require 'hal_presenter/property'
require 'hal_presenter/super_init'

module HALPresenter
  module Attributes
    include SuperInit

    def attribute(*args, **kw_args, &block)
      attributes.delete_if { |attr| attr.name == args.first }
      attributes << Property.new(*args, **kw_args, &block)
    end

    protected

    def attributes
      @__attributes ||= __init_from_superclass(:attributes)
    end
  end
end
