module HALDecorator
  class << self
    attr_accessor :paginate
  end

  class Pagination

    def self.paginate!(serialized, collection)
      new(serialized, collection).call
    end

    def initialize(serialized, collection)
      @serialized = serialized
      @collection = collection
      @self_href = serialized.dig(:_links, :self, :href)
    end

    def call
      return unless should_paginate?
      add_query_to_self
      add_prev_link
      add_next_link
    end

    private

    attr_accessor :serialized, :collection, :self_href

    def should_paginate?
      self_href && current_page
    end

    def query(page)
      if page
        q = "?page=#{page}"
        q << "&per_page=#{per_page}" if per_page
      else
        ""
      end
    end

    def add_query_to_self
      serialized[:_links][:self][:href] += query(current_page)
    end

    def add_prev_link
      return unless prev_page
      serialized[:_links][:prev] = {
        href: self_href + query(prev_page)
      }
    end

    def add_next_link
      return unless next_page
      serialized[:_links][:next] = {
        href: self_href + query(next_page)
      }
    end

    def current_page
      collection.respond_to?(:current_page) && collection.current_page
    end

    def prev_page
      collection.respond_to?(:prev_page) && collection.prev_page
    end

    def next_page
      collection.respond_to?(:next_page) && collection.next_page
    end

    def per_page
      collection.respond_to?(:page_size) && collection.page_size
    end
  end
end

