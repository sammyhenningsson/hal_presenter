require 'hal_decorator/field'

module HALDecorator
  module Embedded
    class Embed < HALDecorator::Field
      attr_reader :decorator_class

      def initialize(name, value = nil, decorator_class: nil, &block)
        super(name, value, &block)
        @decorator_class = decorator_class
      end
    end

    def embed(*args, &block)
      @_embedded ||= []
      @_embedded << Embed.new(*args, &block)
    end

    def embedded
      @_embedded ||= []
      @_embedded.dup
    end
  end
end
