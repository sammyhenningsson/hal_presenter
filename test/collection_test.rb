require 'test_helper'
require 'ostruct'

class CollectionTest < ActiveSupport::TestCase

  Item = Struct.new(:id, :title, :data)

  class CollectionDecorator
    extend HALDecorator
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

  test 'CollectionDecorator.to_collection' do
    payload = CollectionDecorator.to_collection(@items)
    assert_sameish_hash(@expected, JSON.parse(payload))
  end

  test 'HALDecorator.to_collection with opts' do
    options = { page: 2 }
    payload = HALDecorator.to_collection(@items, options)
    @expected[:_links][:next] = { href: '/items?page=2' }
    assert_sameish_hash(@expected, JSON.parse(payload))
  end

  test 'collections can be embedded' do
    Parent = Struct.new(:id, :items)

    parent_decorator = Class.new do
      extend HALDecorator
      attribute :id
      embed :items, decorator_class: CollectionDecorator
    end

    id = 5
    parent = Parent.new(id, @items)

    expected = {
      id: id,
      _embedded: {
        items: @expected
      }
    }

    parent_decorator.to_hal(parent).tap do |payload|
      assert_sameish_hash(
        expected,
        JSON.parse(payload)
      )
    end
  end

  test 'to_collection raises execption when no collection_parameters' do
    class DecoratorWithoutCollection
      extend HALDecorator

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
    collection = CollectionDecorator.from_hal(JSON.generate(@expected))
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
      extend HALDecorator

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

  test 'inheritance of collection' do
    SubItem = Struct.new(:id, :title, :data)

    decorator_a = Class.new(CollectionDecorator) do
      model SubItem
    end

    decorator_b = Class.new(decorator_a) do
      collection of: 'entries' do
        attribute :count

        link :self do
          '/items?page=1'
        end
      end
    end

    decorator_a.to_collection(@items).tap do |payload|
      assert_sameish_hash(
        @expected,
        JSON.parse(payload)
      )
    end

    decorator_b.to_collection(@items).tap do |payload|
      expected = @expected
      expected[:_embedded][:entries] = expected[:_embedded].delete(:items)
      assert_sameish_hash(
        expected,
        JSON.parse(payload)
      )
    end
  end

end
