require 'test_helper'
require 'ostruct'

class CollectionTest < ActiveSupport::TestCase

  Item = Struct.new(:id, :title, :data)

  class Decorator
    include HALDecorator
    model Item

    attribute :title
    attribute :data
    link :self do
      "/items/#{resource.id}"
    end

    collection of: 'items' do
      attribute :count

      link :self do
        '/items?page=1'
      end

      link :next do
        return unless options.key? :page
        "/items?page=#{options[:page]}"
      end
    end
  end

  def setup
    @items = (1..3).map do |i|
      Item.new(i, "title#{i}", "data#{i}")
    end

    @expected = {
      count: 3,
      _links: {
        self: {
          href: '/items?page=1'
        }
      },
      _embedded: {
        items: [
          {
            title: 'title1',
            data: 'data1',
            _links: {
              self: {
                href: '/items/1'
              }
            }
          },
          {
            title: 'title2',
            data: 'data2',
            _links: {
              self: {
                href: '/items/2'
              }
            }
          },
          {
            title: 'title3',
            data: 'data3',
            _links: {
              self: {
                href: '/items/3'
              }
            }
          }
        ]
      }
    }
  end

  test 'Decorator.to_collection' do
    payload = Decorator.to_collection(@items)
    assert_sameish_hash(@expected, JSON.parse(payload))
  end

  test 'HALDecorator.to_collection with opts' do
    options = { page: 2 }
    payload = HALDecorator.to_collection(@items, options)
    @expected[:_links][:next] = { href: '/items?page=2' }
    assert_sameish_hash(@expected, JSON.parse(payload))
  end

  test 'to_collection raises execption when no collection_parameters' do
    class DecoratorWithoutCollection
      include HALDecorator
      model Item

      attribute :title
      attribute :data
      link :self do
        "/items/#{resource.id}"
      end
    end

    assert_raises(HALDecorator::Serializer::Error) do
      DecoratorWithoutCollection.to_collection(@items)
    end
  end

  test 'HALDecorator.from_hal' do
    collection = Decorator.from_hal(JSON.generate(@expected))
    assert_instance_of Array, collection
    assert_equal 3, collection.size
    collection.each_with_index do |item, i|
      i += 1
      assert_instance_of Item, item
      assert_equal "title#{i}", item.title
      assert_equal "data#{i}", item.data
    end
  end

  test 'collection can be called without a block' do
    class DecoratorWithoutCollectionBlock
      include HALDecorator
      model Item

      attribute :title
      attribute :data
      link :self do
        "/items/#{resource.id}"
      end

      collection of: 'items'
    end
    payload = DecoratorWithoutCollectionBlock.to_collection(@items)
    @expected.delete(:count)
    @expected.delete(:_links)
    assert_sameish_hash(@expected, JSON.parse(payload))
  end
end
