require 'hal_presenter/property'
require 'hal_presenter/super_init'

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
    include SuperInit

    class Link < HALPresenter::Property
      attr_reader :type, :deprecation, :profile, :title
      attr_accessor :templated

      def initialize(rel, value = nil, **kwargs, &block)
        if value.nil? && !block_given?
          raise 'link must be called with non nil value or be given a block'
        end

        @type =         kwargs[:type].freeze
        @deprecation =  kwargs[:deprecation].freeze
        @profile =      kwargs[:profile].freeze
        @title =        kwargs[:title].freeze

        curie = kwargs[:curie]&.to_s
        rel = [curie, rel.to_s].join(':') if curie && !curie.empty?

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
      links.delete_if { |link| link.rel == rel }
      links << Link.new(rel, value, **kwargs, &block)
    end

    protected

    def links
      @__links ||= __init_from_superclass(:links)
    end
  end
end
