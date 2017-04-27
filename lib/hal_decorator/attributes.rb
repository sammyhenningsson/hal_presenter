require 'hal_decorator/field'

module HALDecorator
  module Attributes
    def attribute(*args, &block)
      @_attributes ||= []
      @_attributes << Field.new(*args, &block)
    end

    def attributes
      @_attributes ||= []
      @_attributes.dup
    end
  end
end
