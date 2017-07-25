require 'hal_decorator/property'

module HALDecorator
  module Collection

    attr_reader :collection_name

    def as_collection_of(name)
      @collection_name = name.freeze
    end

  end
end
