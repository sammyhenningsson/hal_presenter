require 'hal_decorator/property'

module HALDecorator
  module Links

    class Link < HALDecorator::Property
      attr_reader :http_method
      def initialize(rel, value = nil, http_method: nil, &block)
        if value.nil? && !block_given?
          raise 'link must be called with non nil value or be given a block'
        end
        @http_method = http_method
        super(rel, value, &block)
      end
    end

    def link(rel, value = nil, method: nil, methods: nil, &block)
      @_links ||= []
      @_links << Link.new(rel, value, http_method: method || methods, &block)
    end

    protected

    def links
      @_links ||= []
      @_links.dup
    end
  end
end
