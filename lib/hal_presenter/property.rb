require 'hal_presenter/lazy_evaluator'

module HALPresenter
  class Property
    NO_VALUE = Object.new.freeze

    attr_reader :name, :embed_depth

    def initialize(name, value = NO_VALUE, **kwargs, &block)
      @name = name.to_sym
      @value = value.freeze
      @embed_depth = kwargs[:embed_depth].freeze
      @context = kwargs[:context]
      @lazy = block_given? ? LazyEvaluator.new(block, @context) : nil
    end

    def value(resource = nil, options = {})
      if @lazy
        @lazy.evaluate(resource, options)
      elsif @value != NO_VALUE
        @value
      elsif resource&.respond_to? name_without_curie
        resource.public_send(name_without_curie)
      else
        raise ArgumentError, <<~ERR
          Cannot serialize #{name.inspect}.
          No value given and resource does not respond to #{name_without_curie}. Resource:
          #{resource.inspect}"
          ERR
      end
    end

    def change_context(context)
      @context = context
      @lazy.update_context(context) if @lazy
      self
    end

    def nested_depth_ok?(level)
      return true unless embed_depth
      level <= embed_depth
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
