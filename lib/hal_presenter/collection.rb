require 'hal_presenter/property'

module HALPresenter
  module Collection

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
      @_collection_properties = Properties.new(of, self, &block)
    end

    protected

    def collection_properties
      @_collection_properties ||= __init_collection_params
    end

    def can_serialize_collection?
      !collection_properties.nil?
    end

    private

    def __init_collection_params
      return unless Class === self
      if superclass.respond_to?(:collection_properties, true)
        superclass.collection_properties
      end
    end
  end
end
