require 'test_helper'
require 'ostruct'
require 'kaminari/core'
require 'will_paginate/collection'

class PaginatableCollection
  include Enumerable

  # Used by Sequel
  attr_accessor :current_page, :page_size

  def initialize(count, current_page: 1, page_size: 3)
    @current_page = current_page
    @page_size = page_size
    @count = count
    @collection = page_size.times.map do |n|
      id = (current_page - 1) * page_size + n + 1
      OpenStruct.new(id: id) if id <= count
    end
    @collection.compact!
  end
  
  def each
    @collection.each { |item| yield item }
  end

  # Used by Sequel
  def prev_page
    return if current_page <= 1
    current_page - 1
  end
  
  # Used by Sequel
  def next_page
    return if current_page * page_size >= @count
    current_page + 1
  end
end

class PaginationTest < ActiveSupport::TestCase
  def setup
    HALDecorator.paginate = true

    @serializer = Class.new do
      extend HALDecorator
      attribute :id
      collection of: 'items' do
        link :self, '/the/collection'
      end
    end
  end
  
  def expected(current_page, prev_page, next_page, per_page)
    {_links: {}, _embedded: {}}.tap do |payload|
      payload[:_links][:self] = {
        href: "/the/collection?page=#{current_page}&per_page=#{per_page}"
      }
      if prev_page
        payload[:_links][:prev] = {
          href: "/the/collection?page=#{prev_page}&per_page=#{per_page}"
        }
      end
      if next_page
        payload[:_links][:next] = {
          href: "/the/collection?page=#{next_page}&per_page=#{per_page}"
        }
      end
      payload[:_embedded] = {
        items: per_page.times.map { |n| {id: (current_page - 1) * per_page + n + 1} }
      }
    end
  end

  test 'add next link' do
    collection = PaginatableCollection.new(7, current_page: 1, page_size: 3)
    payload = @serializer.to_collection(collection)
    assert_sameish_hash(
      expected(1, nil, 2, 3),
      JSON.parse(payload)
    )
  end

  test 'add prev' do
    collection = PaginatableCollection.new(10, current_page: 2, page_size: 5)
    payload = @serializer.to_collection(collection)
    assert_sameish_hash(
      expected(2, 1, nil, 5),
      JSON.parse(payload)
    )
  end

  test 'add prev and next from Sequel' do
    collection = PaginatableCollection.new(7, current_page: 2, page_size: 3)
    payload = @serializer.to_collection(collection)
    assert_sameish_hash(
      expected(2, 1, 3, 3),
      JSON.parse(payload)
    )
  end

  test 'add prev and next from Kaminari' do
    Kaminari.config.max_per_page = 3
    items = 9.times.map { |n| OpenStruct.new(id: n + 1) }
    collection = Kaminari::PaginatableArray.new(items, limit: 3, offset: 3)
    payload = @serializer.to_collection(collection)
    assert_sameish_hash(
      expected(2, 1, 3, 3),
      JSON.parse(payload)
    )
  end

  test 'add prev and next from will_paginate' do
    items = 3.times.map { |n| OpenStruct.new(id: n + 4) }
    collection = WillPaginate::Collection.new(2, 3, 9)
    collection.replace(items)
    payload = @serializer.to_collection(collection)
    assert_sameish_hash(
      expected(2, 1, 3, 3),
      JSON.parse(payload)
    )
  end

  test 'paginate option preceeds config' do
    collection = PaginatableCollection.new(7, current_page: 2, page_size: 3)
    payload = @serializer.to_collection(collection, paginate: false)
    payload = JSON.parse(payload, symbolize_names: true)
    assert payload.dig(:_links, :self)
    assert_nil payload.dig(:_links, :next)
    assert_nil payload.dig(:_links, :prev)
  end

  test 'no pagination if next/prev links already present' do
    @serializer.collection of: 'items' do
      link :self, '/the/collection'
      link :next, "some/uri"
    end
    collection = PaginatableCollection.new(7, current_page: 2, page_size: 3)
    payload = @serializer.to_collection(collection)
    payload = JSON.parse(payload, symbolize_names: true)
    assert payload.dig(:_links, :self)
    assert_equal "/the/collection?page=1&per_page=3", payload.dig(:_links, :prev, :href)
    assert_equal "some/uri", payload.dig(:_links, :next, :href)
  end

  test 'existing query parameters are kept' do
    @serializer.collection of: 'items' do
      link :self, '/the/collection?foo=bar'
    end
    collection = PaginatableCollection.new(7, current_page: 2, page_size: 3)
    payload = @serializer.to_collection(collection)
    payload = JSON.parse(payload, symbolize_names: true)
    assert_equal "/the/collection?foo=bar&page=1&per_page=3", payload.dig(:_links, :prev, :href)
    assert_equal "/the/collection?foo=bar&page=3&per_page=3", payload.dig(:_links, :next, :href)
  end
end

