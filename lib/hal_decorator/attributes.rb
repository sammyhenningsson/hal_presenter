require 'hal_decorator/property'

module HALDecorator
  module Attributes
    def attribute(*args, &block)
      @_attributes ||= []
      @_attributes << Property.new(*args, &block)
    end

    def attributes
      @_attributes ||= []
      @_attributes.dup
    end
  end
end
