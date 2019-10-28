require 'set'

module HALPresenter
  class CurieCollection
    class CurieWithReferences
      attr_reader :name, :href, :templated, :rels, :references

      def initialize(curie)
        @name = curie.fetch(:name)
        @href = curie.fetch(:href)
        @templated = curie.fetch(:templated, true)
        @rels = Hash.new { |hash, key| hash[key] = Set.new }
        @references = Hash.new do |hash, key|
          hash[key] = Set.new.compare_by_identity
        end
      end

      def add_reference(rel, reference, type)
        rels[type] << rel
        references[type] << reference
      end

      def <<(other)
        other.rels.each do |type, rels|
          self.rels[type] += rels
        end
        other.references.each do |type, references|
          self.references[type] += references
        end
      end

      def rename(name)
        self.name = name

        rels.each do |type, rels|
          rels.each do |rel|
            new_rel = replace_curie(name, rel)
            references[type].each do |reference|
              reference[new_rel] = reference.delete(rel)
            end
          end
        end
      end

      def to_h
        {
          name: name,
          href: href,
          templated: templated
        }
      end

      private

      attr_writer :name

      def replace_curie(name, rel)
        _, rest = rel.to_s.split(':', 2)
        :"#{name}:#{rest}"
      end
    end

    attr_reader :collection

    def self.extract_from!(hash, resolve_collisions: true)
      new.tap do |curies|
        curies.add_curies(hash[:_links]&.delete(:curies))
        curies.send(:add_references, hash[:_links], :links)
        curies.send(:add_references, hash[:_embedded], :embedded)
        curies.resolve_collisions! if resolve_collisions
      end
    end

    def initialize
      @collection = []
    end

    def add_curies(curies)
      return unless curies

      curies.each do |curie|
        next if find(curie[:name])
        collection << CurieWithReferences.new(curie)
      end
    end

    def generate_curie_name(base)
      name = "#{base}0"
      name = name.next while find(name.to_sym)
      name.to_sym
    end

    def resolve_collisions!
      collection.reverse_each do |curie|
        next if collection.none? { |c| c.name == curie.name && c.href != curie.href }
        new_name = generate_curie_name(curie.name)
        curie.rename new_name
      end

      self
    end

    def to_a
      collection.map(&:to_h)
    end

    def empty?
      collection.empty?
    end

    def each
      return collection.each unless block_given?
      collection.each { |c| yield c }
    end

    private

    def find(name, href = nil)
      return unless name

      collection.find do |c|
        next unless c.name.to_sym == name.to_sym
        href.nil? || c.href == href
      end
    end

    def curie_from(rel)
      parts = rel.to_s.split(':')
      parts.first if parts.size > 1
    end

    def concat(other)
      other.each do |curie|
        if existing = find(curie.name, curie.href)
          existing << curie
        else
          collection << curie
        end
      end
    end

    def add_references(reference, type)
      return unless reference

      reference.each do |rel, values|
        curie_name = curie_from(rel)
        curie = find(curie_name)
        curie&.add_reference(rel, reference, type)

        values = [values] if values.is_a? Hash
        values.each do |value|
          nested = self.class.extract_from!(value, resolve_collisions: false)
          concat nested.collection
        end
      end
    end
  end
end
