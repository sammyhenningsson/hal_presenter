require 'hal_presenter/property'
require 'hal_presenter/super_init'

module HALPresenter

  module ClassMethods
    def base_href=(base)
      @base_href = base&.sub(%r(/*$), '')
    end

    def href(href)
      return href if (@base_href ||= '').empty?
      return href if href =~ %r(\A(\w+://)?[^/])
      @base_href + href
    end
  end

  module Links
    include SuperInit

    class Link < HALPresenter::Property
      attr_reader :type, :deprecation, :profile, :title
      attr_accessor :templated

      alias rel name

      def initialize(rel, value = nil, **kwargs, &block)
        @type =         kwargs[:type].freeze
        @deprecation =  kwargs[:deprecation].freeze
        @profile =      kwargs[:profile].freeze
        @title =        kwargs[:title].freeze

        curie = kwargs[:curie].to_s
        rel = [curie, rel.to_s].join(':') unless curie.empty?

        super(
          rel,
          value,
          embed_depth: kwargs[:embed_depth],
          context: kwargs[:context],
          &block
        )
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

    def self.included(base)
      base.extend ClassMethods
    end

    def link(rel, value = nil, **kwargs, &block)
      if value.nil? && !block_given?
        raise 'link must be called with non nil value or be given a block'
      end

      kwargs[:context] ||= self
      links.delete_if { |link| link.rel == rel }
      Link.new(rel, value, **kwargs, &block).tap do |link|
        links << link
      end
    end

    protected

    def links
      @__links ||= __init_from_superclass(:links)
    end
  end
end
