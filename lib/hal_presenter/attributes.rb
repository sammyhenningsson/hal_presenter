require 'hal_presenter/property'

module HALPresenter
  module Attributes
    def attribute(*args, **kw_args, &block)
      @_attributes ||= __init_attributes
      @_attributes = @_attributes.reject { |attr| attr.name == args.first }
      @_attributes << Property.new(*args, **kw_args, &block)
    end

    protected

    def attributes
      @_attributes ||= __init_attributes
    end

    private

    def __init_attributes
      return [] unless Class === self
      return [] unless superclass.respond_to?(:attributes, true)
      superclass.attributes.each do |attr|
        attr.change_context(self)
      end
    end
  end
end
