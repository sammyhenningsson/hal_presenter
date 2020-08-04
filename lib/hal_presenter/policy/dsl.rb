require 'hal_presenter/policy/rules'

module HALPresenter
  module Policy
    module DSL
      module ClassMethods
        def inherited(child)
          child.instance_variable_set(:@rules, rules.dup)
        end

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

      def delegate_attribute(policy_class, attr, **opts)
        delegate_to(policy_class, :attribute?, args: attr, **opts)
      end

      def delegate_link(policy_class, rel, **opts)
        delegate_to(policy_class, :link?, args: rel, **opts)
      end

      def delegate_embed(policy_class, rel, **opts)
        delegate_to(policy_class, :embed?, args: rel, **opts)
      end

      def delegate_to(policy_class, method, resource: nil, args: nil, **opts)
        resource ||= send(:resource)
        opts = options.merge(opts)
        policy = policy_class.new(current_user, resource, opts)
        args = Array(args)
        args.unshift(method)
        policy.send(*args)
      end

      def __rules
        self.class.rules
      end

      def __check(block)
        !!instance_eval(&block)
      end

    end
  end
end
