require 'hal_presenter/property'

module HALPresenter
  module SerializeHooks

    class Hook
      attr_reader :name, :resource, :options

      def initialize(&block)
        @block = block
      end

      def run(resource, options, arg)
        @resource = resource
        @options = options
        instance_exec(arg, &@block) if @block
      ensure
        @resource = nil
        @options = nil
      end
    end

    def post_serialize(&block)
      @__post_serialize_hook = Hook.new(&block)
    end

    protected

    def post_serialize_hook
      @__post_serialize_hook ||= __init_post_serialize_hook
    end

    private

    def __init_post_serialize_hook
      return unless Class === self
      return unless superclass.respond_to?(:post_serialize_hook, true)
      superclass.post_serialize_hook
    end
  end
end
