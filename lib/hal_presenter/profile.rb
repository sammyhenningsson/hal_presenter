require 'hal_presenter/super_init'

module HALPresenter
  module Profile
    include SuperInit

    def profile(value = nil, **kwargs, &block)
      if value.nil? && !block_given?
        raise 'profile must be called with non nil value or be given a block'
      end

      kwargs[:context] ||= self
      @__semantic_profile = Property.new('profile', value, **kwargs, &block)
    end

    def semantic_profile(object = nil, **kwargs)
      init_profile
      @__semantic_profile&.value(object, kwargs)
    end

    private

    def init_profile
      @__semantic_profile ||= __init_from_superclass(:init_profile, default: nil)
    end
  end
end
