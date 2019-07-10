module HALPresenter
  module Namespace
    class Executor
      attr_reader :presenter, :curie

      def initialize(presenter, curie)
        @presenter = presenter
        @curie = curie
      end

      def run(block)
        instance_exec(&block) if block
      end

      private

      def link(rel, value = nil, **kwargs, &block)
        add_property(:link, rel, value, **kwargs, &block)
      end

      def embed(rel, value = nil, **kwargs, &block)
        add_property(:embed, rel, value, **kwargs, &block)
      end

      def add_property(method, rel, value, **kwargs, &block)
        rel = add_curie!(rel, kwargs)
        kwargs[:context] = presenter
        presenter.public_send(method, rel, value, **kwargs, &block)
      end

      def add_curie!(rel, kwargs)
        ns = kwargs.delete(:curie) { curie }
        "#{ns}:#{rel}"
      end
    end

    def namespace(curie, &block)
      Executor.new(self, curie).run(block)
    end
  end
end
