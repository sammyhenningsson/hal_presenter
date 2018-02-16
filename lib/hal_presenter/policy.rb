module HALPresenter
  module Policy

    def policy(clazz)
      @_policy = clazz
    end

    protected

    def policy_class
      @_policy ||= init_policy
    end

    private

    def init_policy
      return unless Class === self
      return unless superclass.respond_to?(:policy_class, true)
      superclass.policy_class
    end
  end
end