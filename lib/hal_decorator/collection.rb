require 'hal_decorator/property'

module HALDecorator
  module Collection

    class CollectionParameters
      include Attributes
      include Links
      include Curies

      attr_reader :name

      def initialize(name, &block)
        @name = name
        instance_exec(&block) if block_given?
      end
    end

    def collection(of:, &block)
      @_parameters = CollectionParameters.new(of, &block)
    end

    protected

    def collection_parameters
      @_parameters ||= init_collection_params
    end

    private

    def init_collection_params
      return unless is_a? Class
      if superclass.respond_to?(:collection_parameters, true)
        superclass.collection_parameters
      end
    end
  end
end
