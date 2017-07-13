module HALDecorator
  @decorators = {}

  def HALDecorator.register(model:, decorator:)
    @decorators[decorator] = model
  end

  def HALDecorator.unregister(decorator)
    @decorators.delete_if { |d,_| d == decorator }
  end

  def HALDecorator.lookup_model(decorator)
    @decorators[decorator]
  end

  def HALDecorator.lookup_decorator(model)
    clazz = model.class == Class ? model : model.class
    decorators = @decorators.select { |d, m| m == clazz }.keys.compact
    decorators.empty? ? nil : decorators
  end

  module Model
    def model(clazz)
      HALDecorator.register(model: clazz, decorator: self)
    end
  end
end

