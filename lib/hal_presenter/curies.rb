require 'hal_presenter/property'
require 'hal_presenter/super_init'

module HALPresenter
  module Curies
    include SuperInit

    class Curie < HALPresenter::Property
      def to_h(resource = nil, options = {})
        href = value(resource, options)
        return {} unless href

        {
          name: name,
          href: HALPresenter.href(href),
          templated: true
        }
      end
    end

    def curie(rel, value = nil, embed_depth: nil, &block)
      if value.nil? && !block_given?
        raise 'curie must be called with non nil value or be given a block'
      end
      curies.delete_if { |curie| curie.name == rel }
      curies << Curie.new(rel, value, embed_depth: embed_depth, &block)
    end

    protected

    def curies
      @_curies ||= __init_from_superclass(:curies)
    end
  end
end
