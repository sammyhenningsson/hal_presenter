require 'hal_presenter/property'

module HALPresenter

  def self.base_href=(base)
    @base_href = base&.sub(%r(/*$), '')
  end

  def self.href(href)
    return href if (@base_href ||= '').empty?
    return href if href =~ %r(\A(\w+://)?[^/])
    @base_href + href
  end

  module Links

    class Link < HALPresenter::Property
      attr_reader :type, :deprecation, :profile, :title
      attr_accessor :templated

      def initialize(rel, value = nil, **kwargs, &block)
        if value.nil? && !block_given?
          raise 'link must be called with non nil value or be given a block'
        end
        @type =         kwargs[:type]
        @deprecation =  kwargs[:deprecation]
        @profile =      kwargs[:profile]
        @title =        kwargs[:title]
        super(rel, value, embed_depth: kwargs[:embed_depth], &block)
      end

      def rel
        name
      end

      def to_h(resource = nil, options = {})
        href = value(resource, options)
        return {} unless href

        hash = {href: HALPresenter.href(href)}.tap do |h|
          h[:type] = type if type
          h[:deprecation] = deprecation if deprecation
          h[:profile] = profile if profile
          h[:title] = title if title
          h[:templated] = templated if templated
        end

        {rel => hash}
      end
    end

    def link(rel, value = nil, **kwargs, &block)
      @_links ||= __init_links
      @_links = @_links.reject { |link| link.rel == rel }
      @_links << Link.new(rel, value, **kwargs, &block)
    end

    protected

    def links
      @_links ||= __init_links
    end

    private

    def __init_links
      return [] unless Class === self
      return [] unless superclass.respond_to?(:links, true)
      superclass.links.each do |link|
        link.change_scope(self)
      end
    end
  end
end
