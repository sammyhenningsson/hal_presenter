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
        rel = add_curie!(rel, kwargs)
        presenter.link(rel, value, **kwargs, &block)
      end

      def embed(rel, value = nil, **kwargs, &block)
        rel = add_curie!(rel, kwargs)
        presenter.embed(rel, value, **kwargs, &block)
      end

      def add_curie!(rel, kwargs)
        ns = kwargs.delete(:curie) { curie }
        [ns.to_s, rel.to_s].join(':')
      end
    end

    def namespace(curie, &block)
      Executor.new(self, curie).run(block)
    end
  end
end
