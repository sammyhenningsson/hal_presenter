require 'hal_decorator/property'

module HALDecorator
  module Collection

    class CollectionProperties
      attr_reader :type
      def name(name)
        @type = name.to_sym
      end

      def call(&block)
        instance_eval(&block) if block_given?
      end
    end

    def collection(&block)
      return unless block_given?
      data = CollectionProperties.new
      data.call(&block)
      @_collection_properties = data
    end

    def collection_properties
      @_collection_properties.dup
    end
  end
end

