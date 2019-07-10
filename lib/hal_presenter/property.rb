require 'hal_presenter/lazy_evaluator'

module HALPresenter
  class Property
    attr_reader :name, :embed_depth

    def initialize(name, value = nil, embed_depth: nil, &block)
      @name = name.to_sym
      @value = value.freeze
      @embed_depth = embed_depth.freeze
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
      @lazy.update_context(context) if @lazy
      self
    end

    private

    def initialize_copy(source)
      @lazy = source.instance_variable_get(:@lazy).clone
      super
    end
  end
end
