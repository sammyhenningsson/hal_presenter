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
      @_attributes.map(&:dup)
    end

    private

    def init_attributes
      return [] unless self.class == Class
      if self < HALDecorator && ancestors[1].respond_to?(:attributes, true)
        return ancestors[1].attributes
        ancestors[1].attributes.each do |attr|
          attr.change_scope(self)
        end
      else
        []
      end
    end
  end
end
