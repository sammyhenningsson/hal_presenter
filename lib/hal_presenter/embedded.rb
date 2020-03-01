require 'hal_presenter/property'
require 'hal_presenter/super_init'

module HALPresenter
  module Embedded
    include SuperInit

    class Embed < HALPresenter::Property
      attr_reader :presenter_class

      def initialize(name, value = NO_VALUE, **kwargs, &block)
        @presenter_class = kwargs.delete(:presenter_class)
        super(name, value, **kwargs, &block)
      end
    end

    def embed(name, value = Property::NO_VALUE, **kwargs, &block)
      kwargs[:context] ||= self
      embedded.delete_if { |embed| embed.name == name }
      Embed.new(name, value, **kwargs, &block).tap do |embed|
        embedded << embed
      end
    end

    protected

    def embedded
      @__embedded ||= __init_from_superclass(:embedded)
    end
  end
end
