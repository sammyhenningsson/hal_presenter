require 'hal_decorator/property'

module HALDecorator
  module Curies
    def curie(rel, value = nil, &block)
      @_curies ||= []
      @_curies << Property.new(rel, value, &block)
    end

    def curies
      @_curies ||= []
      @_curies.dup
    end
  end
end
