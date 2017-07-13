module HALDecorator
  class Property
    attr_reader :name, :options

    def initialize(name, value = nil, &block)
      @name = name
      @value = value
      @decorator_instance = nil
      return unless block_given?
      @decorator_instance = eval "self", block.binding
      define_singleton_method(:value_from) do |*args|
        block.call(*args)
      end
    end

    def value(object)
      if @decorator_instance
        value_from object
      elsif object && @value.nil?
        object.public_send(name) if object.respond_to?(name)
      else
        @value
      end
    end

    protected

    def method_missing(method, *args, &block)
      return super unless @decorator_instance
      @decorator_instance.send method, *args, &block
    end

  end
end

