module HALPresenter
  @presenters = {}

  def HALPresenter.register(model:, presenter:)
    @presenters[presenter] = model
  end

  def HALPresenter.unregister(presenter)
    @presenters.delete_if { |d,_| d == presenter }
  end

  def HALPresenter.lookup_model(presenter)
    @presenters[presenter]
  end

  def HALPresenter.lookup_presenter(model)
    clazz = model.is_a?(Class) ? model : model.class
    presenters = @presenters.select { |d, m| m == clazz }.keys.compact
    return presenters unless presenters.empty?
    lookup_presenter(clazz.superclass) unless clazz.superclass == BasicObject
  end

  module Model
    def model(clazz)
      HALPresenter.register(model: clazz, presenter: self)
    end

    def inherited(subclass)
      if model = HALPresenter.lookup_model(self)
        HALPresenter.register(model: model, presenter: subclass)
      end
      super
    end
  end
end

