require 'hal_decorator/property'

module HALDecorator
  module Curies
    def curie(rel, value = nil, &block)
      if value.nil? && !block_given?
        raise 'curie must be called with non nil value or be given a block'
      end
      @_curies ||= init_curies
      @_curies = @_curies.reject { |curie| curie.name == rel }
      @_curies << Property.new(rel, value, &block)
    end

    protected

    def curies
      @_curies ||= init_curies
    end

    private

    def init_curies
      return [] unless is_a? Class
      if self < HALDecorator && ancestors[1].respond_to?(:curies, true)
        ancestors[1].curies.each do |curie|
          curie.change_scope(self)
        end
      else
        []
      end
    end
  end
end
