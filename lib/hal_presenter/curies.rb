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

    def curie(rel, value = nil, **kwargs, &block)
      if value.nil? && !block_given?
        raise 'curie must be called with non nil value or be given a block'
      end

      kwargs[:context] ||= self
      curies.delete_if { |curie| curie.name == rel }
      Curie.new(rel, value, **kwargs, &block).tap do |curie|
        curies << curie
      end
    end

    protected

    def curies
      @_curies ||= __init_from_superclass(:curies)
    end
  end
end
