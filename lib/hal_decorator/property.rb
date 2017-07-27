module HALDecorator
  class Property
    attr_reader :name, :resource, :options

    alias :resources :resource

    def initialize(name, value = nil, &block)
      @name = name
      @value = value
      @scope = nil
      return unless block_given?
      @scope = eval 'self', block.binding
      define_singleton_method(:value_from_block, &block)
    end

    def value(resource = nil, options = {})
      @resource = resource
      @options = options
      if @scope
        value_from_block
      elsif resource && @value.nil?
        resource.public_send(name) if resource.respond_to?(name)
      else
        @value
      end
    ensure
      reset
    end

    def method_missing(method, *args, &block)
      if @scope&.respond_to? method
        define_singleton_method(method) { |*a, &b| @scope.public_send method, *a, &b }
        return public_send(method, *args, &block)
      end
      super
    end

    def respond_to_missing?(method, include_private = false)
      return true if @scope&.respond_to? method
      super
    end

    private

    def reset
      @resource = nil
      @options = nil
    end
  end
end
