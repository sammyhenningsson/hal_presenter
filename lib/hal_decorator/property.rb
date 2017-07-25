module HALDecorator
  class Property
    attr_reader :name, :object, :options

    def initialize(name, value = nil, &block)
      @name = name
      @value = value
      @scope = nil
      return unless block_given?
      @scope = eval 'self', block.binding
      define_singleton_method(:value_from_block, &block)
    end

    def value(object = nil, options = {})
      @object = object
      @options = options
      if @scope
        value_from_block
      elsif object && @value.nil?
        object.public_send(name) if object.respond_to?(name)
      else
        @value
      end
    ensure
      reset
    end

    def method_missing(method, *args, &block)
      if @scope&.respond_to? method
        define_singleton_method(method) do |*args, &b|
          @scope.send method, *args, &b
        end
        return send(method, *args, &block)
      end
      super
    end

    def respond_to_missing?(method, include_private = false)
      return true if @scope&.respond_to? method
      super
    end

    private

    def reset
      @object = nil
      @options = nil
    end
  end
end
