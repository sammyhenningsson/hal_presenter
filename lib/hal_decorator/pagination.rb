module HALDecorator
  class << self
    attr_accessor :paginate
  end

  # TODO: Support Kaminari and Will_paginate
 
  class Pagination

    class Uri
      def self.parse(str)
        uri = nil
        query = nil
        unless str.nil? || str.empty?
          if m = str.match(%r(\A([^\?]+)\??([^\#]+)?.*\Z))
            uri = m[1]
            query = query_from_string m[2]
          end
        end
        new(uri, query)
      end

      def self.query_from_string(str)
        return {} if str.nil? || str.empty?
        str.split('&').each_with_object({}) do |pair, q|
          key_value = pair.split('=')
          q[key_value[0]] = key_value[1];
        end
      end

      def initialize(uri, query)
        @uri = uri
        @query = query
      end

      def +(query)
        self.class.new(@uri, @query.merge(query))
      end

      def to_s
        return if @uri.nil?
        @uri.dup.tap do |uri|
          next if @query.nil? || @query.empty?
          uri << "?" + @query.map { |k,v| "#{k}=#{v}" }.join('&')
        end
      end
    end

    def self.paginate!(serialized, collection)
      new(serialized, collection).call
    end

    def initialize(serialized, collection)
      @serialized = serialized
      @collection = collection
      @self_uri = Uri.parse serialized.dig(:_links, :self, :href)
    end

    def call
      return unless should_paginate?
      add_query_to_self
      add_prev_link
      add_next_link
    end

    private

    attr_accessor :serialized, :collection, :self_uri

    def should_paginate?
      self_uri && current_page
    end

    def query(page)
      return {} unless page
      {
        page: page,
        per_page: per_page,
      }
    end

    def add_query_to_self
      serialized[:_links][:self][:href] = (self_uri + query(current_page)).to_s
    end

    def add_prev_link
      return unless prev_page
      return if serialized[:_links][:prev]
      serialized[:_links][:prev] = {
        href: (self_uri + query(prev_page)).to_s
      }
    end

    def add_next_link
      return unless next_page
      return if serialized[:_links][:next]
      serialized[:_links][:next] = {
        href: (self_uri + query(next_page)).to_s
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

