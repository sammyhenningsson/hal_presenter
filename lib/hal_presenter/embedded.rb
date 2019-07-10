require 'hal_presenter/property'
require 'hal_presenter/super_init'

module HALPresenter
  module Embedded
    include SuperInit

    class Embed < HALPresenter::Property
      attr_reader :presenter_class

      def initialize(name, value = nil, **kw_args, &block)
        @presenter_class = kw_args.delete(:presenter_class)
        super(name, value, **kw_args, &block)
      end
    end

    def embed(*args, **kw_args, &block)
      embedded.delete_if { |embed| embed.name == args.first }
      embedded << Embed.new(*args, **kw_args, &block)
    end

    protected

    def embedded
      @__embedded ||= __init_from_superclass(:embedded)
    end
  end
end
