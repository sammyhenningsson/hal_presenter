module HALPresenter
  module SuperInit
    private

    def __init_from_superclass(method, default: [])
      return default unless Class === self
      return default unless superclass.respond_to?(method, true)

      if default.respond_to? :each
        superclass.send(method).map do |prop|
          prop.clone.change_context(self)
        end
      else
        prop = superclass.send(method)
        return default unless prop
        prop.clone.change_context(self)
      end
    end
  end
end
