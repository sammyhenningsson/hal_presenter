require 'hal_decorator/property'

module HALDecorator
  module Embedded
    class Embed < HALDecorator::Property
      attr_reader :decorator_class

      def initialize(name, value = nil, decorator_class: nil, &block)
        super(name, value, &block)
        @decorator_class = decorator_class
      end
    end

    def embed(*args, &block)
      @_embedded ||= init_embedded
      @_embedded = @_embedded.reject { |embed| embed.name == args.first }
      @_embedded << Embed.new(*args, &block)
    end

    protected

    def embedded
      @_embedded ||= init_embedded
    end

    private

    def init_embedded
      return [] unless is_a? Class
      return [] unless superclass.respond_to?(:embedded, true)
      superclass.embedded.each do |embed|
        embed.change_scope(self)
      end
    end
  end
end
