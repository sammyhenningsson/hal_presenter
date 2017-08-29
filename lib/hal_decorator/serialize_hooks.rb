require 'hal_decorator/property'

module HALDecorator
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
      @_post_serialize_hook = Hook.new(&block)
    end

    protected

    def post_serialize_hook
      @_post_serialize_hook ||= init_post_serialize_hook
    end

    private

    def init_post_serialize_hook
      return unless is_a? Class
      return unless superclass.respond_to?(:post_serialize_hook, true)
      superclass.post_serialize_hook
    end
  end
end
