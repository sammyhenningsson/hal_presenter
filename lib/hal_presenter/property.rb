require 'hal_presenter/lazy_evaluator'

module HALPresenter
  class Property
    attr_reader :name, :embed_depth

    def initialize(name, value = nil, **kwargs, &block)
      @name = name.to_sym
      @value = value.freeze
      @embed_depth = kwargs[:embed_depth].freeze
      @context = kwargs[:context]
      @lazy = block_given? ? LazyEvaluator.new(block, @context) : nil
    end

    def value(resource = nil, options = {})
      if @lazy
        @lazy.evaluate(resource, options)
      elsif @value
        @value
      elsif resource&.respond_to? name_without_curie
        resource.public_send(name_without_curie)
      end
    end

    def change_context(context)
      @context = context
      @lazy.update_context(context) if @lazy
      self
    end

    private

    def initialize_copy(source)
      @lazy = source.instance_variable_get(:@lazy).clone
      super
    end

    def name_without_curie
      @name_without_curie ||= name.to_s.split(':', 2).last
    end
  end
end
