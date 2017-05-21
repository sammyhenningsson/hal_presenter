require 'hal_decorator/field'

module HALDecorator
  module Links

    class Link < HALDecorator::Field
      attr_reader :http_method
      def initialize(rel, value = nil, http_method: nil, &block)
        @http_method = http_method
        super(rel, value, &block)
      end
    end

    def link(rel, value = nil, method: nil, &block)
      @_links ||= []
      @_links << Link.new(rel, value, http_method: method, &block)
    end

    def links
      @_links ||= []
      @_links.dup
    end
  end
end
