require 'hal_decorator/property'

module HALDecorator
  module Collection

    attr_reader :collection_name

    class CollectionParameters
      include Attributes
      include Links
      include Curies

      attr_reader :name

      def initialize(name, &block)
        @name = name
        instance_exec(&block)
      end
    end

    def collection(of: nil, &block)
      @parameters = CollectionParameters.new(of, &block)
    end

    def collection_parameters
      @parameters
    end
  end
end
