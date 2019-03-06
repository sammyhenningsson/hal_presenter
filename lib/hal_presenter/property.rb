require 'hal_presenter/lazy_evaluator'

module HALPresenter
  class Property

    attr_reader :name, :embed_depth

    def initialize(name, value = nil, embed_depth: nil, &block)
      @name = name
      @value = value
      @embed_depth = embed_depth
      @lazy = block_given? && LazyEvaluator.new(block)
    end

    def value(resource = nil, options = nil)
      if @lazy
        @lazy.evaluate(resource, options)
      elsif resource && @value.nil?
        resource.public_send(name) if resource.respond_to?(name)
      else
        @value
      end
    end

    def change_context(context)
      return unless @lazy
      @lazy.update_context(context)
    end
  end
end
