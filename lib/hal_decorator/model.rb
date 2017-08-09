module HALDecorator
  @decorators = {}

  def HALDecorator.register(model:, decorator:)
    @decorators[decorator] = model
  end

  def HALDecorator.unregister(decorator)
    @decorators.delete_if { |d,_| d == decorator }
  end

  def HALDecorator.lookup_model(decorator)
    @decorators[decorator] || self < HALDecorator && lookup_model(ancestors[1])

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

    def inherited(subclass)
      if model = HALDecorator.lookup_model(self)
        HALDecorator.register(model: model, decorator: subclass)
      end
      super
    end
  end
end

