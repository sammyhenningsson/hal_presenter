require 'hal_decorator/field'

module HALDecorator
  module Links
    def link(rel, value = nil, &block)
      @_links ||= []
      @_links << Field.new(rel, value, &block)
    end

    def links
      @_links ||= []
      @_links.dup
    end
  end
end
