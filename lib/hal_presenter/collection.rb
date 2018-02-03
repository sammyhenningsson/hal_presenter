require 'hal_presenter/property'

module HALPresenter
  module Collection

    class CollectionParameters
      include Attributes
      include Links
      include Curies
      include Embedded

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

    def can_serialize_collection?
      !collection_parameters.nil?
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
