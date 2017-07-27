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
        instance_exec(&block) if block_given?
      end
    end

    def collection(of:, &block)
      @_parameters = CollectionParameters.new(of, &block)
    end

    protected

    def collection_parameters
      @_parameters ||= nil
    end
  end
end
