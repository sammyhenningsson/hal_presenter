module HALPresenter
  @presenters = {}

  def HALPresenter.register(model:, presenter:)
    return unless presenter && model
    @presenters[presenter] = model
  end

  def HALPresenter.unregister(presenter)
    @presenters.delete_if { |d,_| d == presenter }
  end

  def HALPresenter.lookup_model(presenter)
    @presenters[presenter]
  end

  def HALPresenter.lookup_presenter(model)
    lookup_presenters(model).last
  end

  def HALPresenter.lookup_presenters(model)
    clazz = model.is_a?(Class) ? model : model.class
    presenters = @presenters.select { |_d, m| m == clazz }.keys
    return presenters unless presenters.empty?
    return [] unless clazz < BasicObject
    lookup_presenters(clazz.superclass)
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

