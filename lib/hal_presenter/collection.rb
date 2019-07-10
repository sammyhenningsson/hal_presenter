require 'hal_presenter/property'
require 'hal_presenter/super_init'

module HALPresenter
  module Collection
    include SuperInit

    class Properties
      include Attributes
      include Links
      include Curies
      include Embedded

      attr_reader :name, :scope

      def initialize(name, scope, &block)
        @name = name
        return unless block_given?
        @scope = scope
        instance_exec(&block)
      end

      def attribute(*args, **kwargs, &block)
        kwargs[:context] = scope
        super
      end

      def link(rel, value = nil, **kwargs, &block)
        kwargs[:context] = scope
        super
      end

      def curie(rel, value = nil, **kwargs, &block)
        kwargs[:context] = scope
        super
      end

      def embed(*args, **kwargs, &block)
        kwargs[:context] = scope
        super
      end

      def change_context(context)
        @scope = context
        self
      end

      private

      def method_missing(method, *args, &block)
        return super unless scope&.respond_to? method
        define_singleton_method(method) { |*a, &b| scope.public_send method, *a, &b }
        public_send(method, *args, &block)
      end

      def respond_to_missing?(method, include_private = false)
        return true if scope&.respond_to? method
        super
      end
    end

    def collection(of:, &block)
      @__collection_properties = Properties.new(of, self, &block)
    end

    protected

    def collection_properties
      @__collection_properties ||= __init_from_superclass(:collection_properties, default: nil)
    end

    def can_serialize_collection?
      !collection_properties.nil?
    end
  end
end
