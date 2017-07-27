require 'hal_decorator/property'

module HALDecorator
  module Curies
    def curie(rel, value = nil, &block)
      if value.nil? && !block_given?
        raise 'curie must be called with non nil value or be given a block'
      end
      @_curies ||= []
      @_curies << Property.new(rel, value, &block)
    end

    protected

    def curies
      @_curies ||= []
      @_curies.dup
    end
  end
end
