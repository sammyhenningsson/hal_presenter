require 'hal_presenter/property'

module HALPresenter
  module Embedded
    class Embed < HALPresenter::Property
      attr_reader :presenter_class

      def initialize(name, value = nil, **kw_args, &block)
        @presenter_class = kw_args.delete(:presenter_class)
        super(name, value, **kw_args, &block)
      end
    end

    def embed(*args, **kw_args, &block)
      @_embedded ||= init_embedded
      @_embedded = @_embedded.reject { |embed| embed.name == args.first }
      @_embedded << Embed.new(*args, **kw_args, &block)
    end

    protected

    def embedded
      @_embedded ||= init_embedded
    end

    private

    def init_embedded
      return [] unless Class === self
      return [] unless superclass.respond_to?(:embedded, true)
      superclass.embedded.each do |embed|
        embed.change_scope(self)
      end
    end
  end
end
