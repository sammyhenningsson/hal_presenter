module HALDecorator
  module Policy
    module DSL

      module ClassMethods
        attr_reader :rules

        def attribute(name, &block)
          @rules ||= {}
          @rules[:attributes] ||= {}
          @rules[:attributes][name] = block
        end

        def link(rel, &block)
          @rules ||= {}
          @rules[:links] ||= {}
          @rules[:links][rel] = block
        end

        def embed(name, &block)
          @rules ||= {}
          @rules[:embeds] ||= {}
          @rules[:embeds][name] = block
        end
      end

      def self.included(mod)
        mod.extend(ClassMethods)
      end

      def initialize(current_user = nil, resource)
        @current_user = current_user
        @resource = resource
      end

      def attribute?(name)
        run self.class.rules&.dig(:attributes, name)
      end

      def link?(rel)
        run self.class.rules&.dig(:links, rel)
      end

      def embed?(name)
        run self.class.rules&.dig(:embeds, name)
      end

      private

      attr_reader :current_user, :resource

      def run(block)
        return false unless block && block.respond_to?(:call)
        instance_eval(&block) && true || false
      end

    end
  end
end
