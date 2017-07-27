require 'test_helper'
require 'ostruct'

class SerializerTest < ActiveSupport::TestCase

  Child = Struct.new(:title, :data)

  class ParentDecorator
    include HALDecorator

    attribute :title
  end

  class ChildDecorator
    include HALDecorator
    model Child

    attribute :data do
      options[:child_data] || resource.data
    end
  end

  class Decorator
    include HALDecorator

    attribute :title
    link :self do
      "/items/#{resource.id}"
    end
    link :edit, method: :put do
      options[:edit_uri] || '/items/5/edit'
    end
    link :'doc:user', '/some/uri/with/namespace'
    curie :'doc', '/some/templated/uri/{rel}'
    embed :parent, decorator_class: ParentDecorator
    embed :children, decorator_class: ChildDecorator
  end

  def setup

    parent = OpenStruct.new(
      title: :some_parent,
      data: :parent_data
    )

    child1 = Child.new(:child1, :child1_data)
    child2 = Child.new(:child2, :child2_data)

    @obj = OpenStruct.new(
      id: 5,
      title: 'some_title',
      comment: 'some_comments',
      parent: parent,
      children: [child1, child2]
    )

    @expected = {
      title: 'some_title',
      _links: {
        self: {
          href: '/items/5'
        },
        edit: {
          href: '/items/5/edit',
          method: 'put',
        },
        'doc:user': {
          href: '/some/uri/with/namespace'
        },
        curies: [
          {
            name: 'doc',
            href: '/some/templated/uri/{rel}',
            templated: true
          }
        ],
      },
      _embedded: {
        parent: {
          title: 'some_parent'
        },
        children: [
          {
            data: 'child1_data'
          },
          {
            data: 'child2_data'
          }
        ]
      }
    }
  end

  test 'HALDecorator.to_hal' do
    options = { decorator: Decorator }
    payload = HALDecorator.to_hal(@obj, options)
    assert_sameish_hash(@expected, JSON.parse(payload))
  end

  test 'Decorator.to_hal' do
    payload = Decorator.to_hal(@obj)
    assert_sameish_hash(@expected, JSON.parse(payload))
  end

  test 'Decorator.to_hal with options' do
    options = { edit_uri: 'foo', child_data: 'optional_data' }
    payload = Decorator.to_hal(@obj, options)
    result = JSON.parse(payload, symbolize_names: true)

    assert_equal 'foo', result[:_links][:edit][:href]
    refute result[:_embedded][:children].empty?
    result[:_embedded][:children].each do |child|
      assert_equal 'optional_data', child[:data]
    end
  end

  test 'Serializer respects private methods on resource' do
    class FurtiveChild
      attr_reader :title, :data
      def initialize(title, data)
        @title = title
        @data = data
      end
      private :data
    end

    obj = FurtiveChild.new("foo", "bar")
    assert_raises NoMethodError do
      ChildDecorator.to_hal(obj)
    end
  end

  test 'multiple nested embeds' do
    class C
      include HALDecorator
      link :self, '/grandchild'
      attribute :data { resource.data }
    end
    class B
      include HALDecorator
      link :self, '/child'
      attribute :data { resource.data }
      embed :child, decorator_class: C
    end
    class A
      include HALDecorator
      link :self, '/'
      attribute :data { resource.data }
      embed :child, decorator_class: B
    end

    obj = OpenStruct.new(
      data: 'parent',
      child: OpenStruct.new(
        data: 'child',
        child: OpenStruct.new(
          data: 'grandchild'
        )
      )
    )

    expected = {
      data: 'parent',
      _links: {
        self: {
          href: '/'
        }
      },
      _embedded: {
        child: {
          data: 'child',
          _links: {
            self: {
              href: '/child'
            }
          },
          _embedded: {
            child: {
              data: 'grandchild',
              _links: {
                self: {
                  href: '/grandchild'
                }
              }
            }
          }
        }
      }
    }

    payload = A.to_hal(obj)
    assert_sameish_hash(expected, JSON.parse(payload))
  end

end
