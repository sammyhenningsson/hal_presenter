require 'hal_presenter/property'
require 'hal_presenter/super_init'

module HALPresenter
  module Attributes
    include SuperInit

    def attribute(name, value = Property::NO_VALUE, **kwargs, &block)
      kwargs[:context] ||= self
      attributes.delete_if { |attr| attr.name == name }
      Property.new(name, value, **kwargs, &block).tap do |attr|
        attributes << attr
      end
    end

    protected

    def attributes
      @__attributes ||= __init_from_superclass(:attributes)
    end
  end
end
