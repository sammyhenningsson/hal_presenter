module HALDecorator
  class Field
    attr_reader :name, :options

    def initialize(name, value = nil, &block)
      @name = name
      @value = value
      @decorator_instance = nil
      return unless block_given?
      @decorator_instance = eval "self", block.binding
      define_singleton_method(:call_block, block)
    end

    def value(object)
      if @decorator_instance
        call_block object
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

