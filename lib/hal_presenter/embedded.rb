require 'hal_presenter/property'
require 'hal_presenter/super_init'

module HALPresenter
  module Embedded
    include SuperInit

    class Embed < HALPresenter::Property
      attr_reader :presenter_class

      def initialize(name, value = nil, **kwargs, &block)
        @presenter_class = kwargs.delete(:presenter_class)
        super(name, value, **kwargs, &block)
      end
    end

    def embed(*args, **kwargs, &block)
      kwargs[:context] ||= self
      embedded.delete_if { |embed| embed.name == args.first }
      Embed.new(*args, **kwargs, &block).tap do |embed|
        embedded << embed
      end
    end

    protected

    def embedded
      @__embedded ||= __init_from_superclass(:embedded)
    end
  end
end
