require 'hal_presenter/property'

module HALPresenter
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
      return [] unless superclass.respond_to?(:attributes, true)
      superclass.attributes.each do |attr|
        attr.change_scope(self)
      end
    end
  end
end
