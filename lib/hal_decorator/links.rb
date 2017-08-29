require 'hal_decorator/property'

module HALDecorator

  def self.base_href=(base)
    @base_href = base&.sub(%r(/*$), '')
  end

  def self.href(href)
    return href if (@base_href ||= '').empty?
    return href if href =~ %r(\A(\w+://)?[^/])
    @base_href + href
  end

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

      def rel
        name
      end
    end

    def link(rel, value = nil, method: nil, methods: nil, &block)
      @_links ||= init_links
      @_links = @_links.reject { |link| link.rel == rel }
      @_links << Link.new(rel, value, http_method: method || methods, &block)
    end

    protected

    def links
      @_links ||= init_links
    end

    private

    def init_links
      return [] unless is_a? Class
      return [] unless superclass.respond_to?(:links, true)
      superclass.links.each do |link|
        link.change_scope(self)
      end
    end
  end
end
