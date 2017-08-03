require 'hal_decorator/property'

module HALDecorator
  module Attributes
    def attribute(*args, &block)
      @_attributes ||= init_attributes
      @_attributes = @_attributes.reject do |attr|
        attr.name == args.first
      end
      @_attributes << Property.new(*args, &block)
    end

    protected

    def attributes
      @_attributes ||= init_attributes
      @_attributes.dup
    end

    private

    def init_attributes
      return [] unless self.class == Class
      if self < HALDecorator && ancestors[1].respond_to?(:attributes, true)
        ancestors[1].attributes
      else
        []
      end
    end

    def super_class
    end
  end
end
