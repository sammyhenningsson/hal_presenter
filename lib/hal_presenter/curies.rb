require 'hal_presenter/property'

module HALPresenter
  module Curies
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

    def curie(rel, value = nil, **kw_args, &block)
      if value.nil? && !block_given?
        raise 'curie must be called with non nil value or be given a block'
      end
      @_curies ||= init_curies
      @_curies = @_curies.reject { |curie| curie.name == rel }
      @_curies << Curie.new(rel, value, **kw_args, &block)
    end

    protected

    def curies
      @_curies ||= init_curies
    end

    private

    def init_curies
      return [] unless Class === self
      return [] unless superclass.respond_to?(:curies, true)
      superclass.curies.each do |curie|
        curie.change_scope(self)
      end
    end
  end
end
