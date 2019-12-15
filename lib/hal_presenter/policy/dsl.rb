module HALPresenter
  module Policy
    module DSL
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

      module ClassMethods
        def allow_by_default(*types)
          rules.defaults(*types, value: true)
        end

        def attribute(*names, &block)
          block ||= Proc.new { true }
          names.each { |name| rules.add_attribute(name, block) }
        end

        def link(*rels, &block)
          block ||= Proc.new { true }
          rels.each { |rel| rules.add_link(rel, block) }
        end

        def embed(*names, &block)
          block ||= Proc.new { true }
          names.each { |name| rules.add_embed(name, block) }
        end

        def rules
          @rules ||= Rules.new
        end
      end

      def self.included(mod)
        mod.extend(ClassMethods)
      end

      def initialize(current_user, resource, options = {})
        @current_user = current_user
        @resource = resource
        @options = options
      end

      def attribute?(name)
        __check __rules.attribute_rule_for(name)
      end

      def link?(rel)
        return true if rel == :self
        __check __rules.link_rule_for(rel)
      end

      def embed?(name)
        __check __rules.embed_rule_for(name)
      end

      private

      attr_reader :current_user, :resource, :options

      def __rules
        self.class.rules
      end

      def __check(block)
        !!instance_eval(&block)
      end

    end
  end
end
