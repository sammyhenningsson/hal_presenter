require 'test_helper'
require 'ostruct'

class CollectionTest < ActiveSupport::TestCase

  class ChildPresenter
    extend HALPresenter
    attribute :greeting
  end

  Item = Struct.new(:id, :title, :data)

  class CollectionPresenter
    extend HALPresenter
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

      embed :child, presenter_class: ChildPresenter do
        OpenStruct.new(greeting: 'hello')
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
        child: {
          greeting: 'hello'
        },
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

  test 'CollectionPresenter.to_collection' do
    payload = CollectionPresenter.to_collection(@items)
    assert_sameish_hash(@expected, JSON.parse(payload))
  end

  test 'HALPresenter.to_collection with opts' do
    options = { page: 2 }
    payload = HALPresenter.to_collection(@items, options)
    @expected[:_links][:next] = { href: '/items?page=2' }
    assert_sameish_hash(@expected, JSON.parse(payload))
  end

  test 'collections can be embedded' do
    Parent = Struct.new(:id, :items)

    parent_presenter = Class.new do
      extend HALPresenter
      attribute :id
      embed :items, presenter_class: CollectionPresenter
    end

    id = 5
    parent = Parent.new(id, @items)

    expected = {
      id: id,
      _embedded: {
        items: @expected
      }
    }

    parent_presenter.to_hal(parent).tap do |payload|
      assert_sameish_hash(
        expected,
        JSON.parse(payload)
      )
    end
  end

  test 'to_collection raises execption when no collection_parameters' do
    class PresenterWithoutCollection
      extend HALPresenter

      attribute :title
      attribute :data
      link :self do
        "/items/#{resource.id}"
      end
    end

    assert_raises(HALPresenter::Serializer::Error) do
      PresenterWithoutCollection.to_collection(@items)
    end
  end

  test 'HALPresenter.from_hal' do
    collection = CollectionPresenter.from_hal(JSON.generate(@expected))
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
    class PresenterWithoutCollectionBlock
      extend HALPresenter

      attribute :title
      attribute :data
      link :self do
        "/items/#{resource.id}"
      end

      collection of: 'items'
    end
    payload = PresenterWithoutCollectionBlock.to_collection(@items)
    @expected.delete(:count)
    @expected.delete(:_links)
    @expected[:_embedded].delete(:child)
    assert_sameish_hash(@expected, JSON.parse(payload))
  end

  test 'inheritance of collection' do
    SubItem = Struct.new(:id, :title, :data)

    # presenter_a inherits CollectionPresenter
    presenter_a = Class.new(CollectionPresenter) do
      model SubItem
    end

    # presenter_b inherits presenter_a
    presenter_b = Class.new(presenter_a) do
      collection of: 'entries' do
        attribute :count

        link :self do
          '/items?page=1'
        end
      end
    end

    presenter_a.to_collection(@items).tap do |payload|
      assert_sameish_hash(
        @expected,
        JSON.parse(payload)
      )
    end

    presenter_b.to_collection(@items).tap do |payload|
      expected = @expected
      expected[:_embedded].delete(:child)
      expected[:_embedded][:entries] = expected[:_embedded].delete(:items)
      assert_sameish_hash(
        expected,
        JSON.parse(payload)
      )
    end
  end

end
