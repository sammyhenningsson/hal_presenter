module HALPresenter
  module Policy
    class Rules
      DEFAULT_PROC = Proc.new { false }

      def attributes
        @attributes ||= Hash.new(DEFAULT_PROC)
      end

      def links
        @links ||= Hash.new(DEFAULT_PROC)
      end

      def embedded
        @embedded ||= Hash.new(DEFAULT_PROC)
      end

      def dup
        super.tap do |copy|
          copy.instance_variable_set(:@attributes, attributes.dup)
          copy.instance_variable_set(:@links, links.dup)
          copy.instance_variable_set(:@embedded, embedded.dup)
        end
      end

      private :attributes, :links, :embedded

      def defaults(*types, value: false)
        types.each do |t|
          send(t).default= Proc.new { value }
        end
      end

      def attribute_rule_for(name)
        attributes[name]
      end

      def add_attribute(name, block)
        attributes[name] = block
      end

      def link_rule_for(rel)
        return links[rel] if links.key? rel
        links[strip_curie(rel)]
      end

      def add_link(rel, block)
        links[rel] = block
      end

      def embed_rule_for(name)
        return embedded[name] if embedded.key? name
        embedded[strip_curie(name)]
      end

      def add_embed(name, block)
        embedded[name] = block
      end

      def strip_curie(rel)
        rel.to_s.split(':', 2)[1]&.to_sym
      end
    end
  end
end
