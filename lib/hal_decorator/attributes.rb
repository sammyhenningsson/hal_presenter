require 'hal_decorator/property'

module HALDecorator
  module Attributes
    def attribute(*args, &block)
      @_attributes ||= init_attributes
      @_attributes = @_attributes.reject { |attr| attr.name == args.first }
      @_attributes << Property.new(*args, &block)
    end

    protected

    def attributes
      @_attributes ||= init_attributes
    end

    private

    def init_attributes
      return [] unless is_a? Class
      if self < HALDecorator && ancestors[1].respond_to?(:attributes, true)
        ancestors[1].attributes.each do |attr|
          attr.change_scope(self)
        end
      else
        []
      end
    end
  end
end
