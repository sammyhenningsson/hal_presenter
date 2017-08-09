require 'test_helper'
require 'ostruct'

class SerializerTest < ActiveSupport::TestCase

  class Child
    attr_accessor :title, :data
    def initialize(title, data)
      @title = title
      @data = data
    end
  end

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
    c = Class.new do
      include HALDecorator
      link :self, '/grandchild'
      attribute :data { resource.data }
    end
    b = Class.new do
      include HALDecorator
      link :self, '/child'
      attribute :data { resource.data }
      embed :child, decorator_class: c
    end
    a = Class.new do
      include HALDecorator
      link :self, '/'
      attribute :data { resource.data }
      embed :child, decorator_class: b
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

    payload = a.to_hal(obj)
    assert_sameish_hash(expected, JSON.parse(payload))
  end

  test 'inheritance of model' do
    foo = Class.new(Child) do
      def f; 'F'; end
    end

    decorator_a = Class.new(ChildDecorator) do
      attribute :a, 'A'
    end

    decorator_b = Class.new(decorator_a) do
      model foo
      attribute :f
    end

    child = Child.new(:child1, :child1_data)
    foo = foo.new(:foo1, :foo1_data)

    HALDecorator.to_hal(child).tap do |payload|
      assert_sameish_hash(
        {
          data: 'child1_data',
          a: 'A'
        },
        JSON.parse(payload)
      )
    end

    HALDecorator.to_hal(foo).tap do |payload|
      assert_sameish_hash(
        {
          data: 'foo1_data',
          a: 'A',
          f: 'F'
        },
        JSON.parse(payload)
      )
    end
  end

  test 'inheritance of attributes' do
    decorator_a = Class.new do
      include HALDecorator
      def self.a; "A"; end
      attribute :a { a << "#{options[:b] && b}" << "#{options[:c] && c}" }
    end

    decorator_b = Class.new(decorator_a) do
      def self.b; "B"; end
      attribute :b { b }
      attribute :x { "#{a}" }
    end

    decorator_c = Class.new(decorator_b) do
      def self.c; "C"; end
      attribute :b, 'bc'
      attribute :c { c }
      attribute :y { "#{a}#{b}" }
    end

    decorator_a.to_hal(nil).tap do |payload|
      assert_sameish_hash({a: 'A'}, JSON.parse(payload))
    end

    decorator_b.to_hal(nil).tap do |payload|
      assert_sameish_hash({a: 'A', b: 'B', x: 'A'}, JSON.parse(payload))
    end

    decorator_c.to_hal(nil, {c: true}).tap do |payload|
      assert_sameish_hash({a: 'AC', b: 'bc', c: 'C', x: 'A', y: 'AB'}, JSON.parse(payload))
    end
  end

  test 'inheritance of links' do
    decorator_a = Class.new do
      include HALDecorator
      def self.a; "A"; end
      link :a { a << "#{options[:b] && b}" << "#{options[:c] && c}" }
    end

    decorator_b = Class.new(decorator_a) do
      def self.b; "B"; end
      link :b { b }
      link :x { "#{a}" }
    end

    decorator_c = Class.new(decorator_b) do
      def self.c; "C"; end
      link :b, 'bc'
      link :c { c }
      link :y { "#{a}#{b}" }
    end

    decorator_a.to_hal(nil).tap do |payload|
      assert_sameish_hash(
        {
          _links: {
            a: {
              href: 'A'
            }
          }
        },
        JSON.parse(payload)
      )
    end

    decorator_b.to_hal(nil).tap do |payload|
      assert_sameish_hash(
        {
          _links: {
            a: {
              href: 'A'
            },
            b: {
              href: 'B'
            },
            x: {
              href: 'A'
            }
          }
        },
        JSON.parse(payload)
      )
    end

    decorator_c.to_hal(nil, {c: true}).tap do |payload|
      assert_sameish_hash(
        {
          _links: {
            a: {
              href: 'AC'
            },
            b: {
              href: 'bc'
            },
            c: {
              href: 'C'
            },
            x: {
              href: 'A'
            },
            y: {
              href: 'AB'
            }
          }
        },
        JSON.parse(payload)
      )
    end
  end

  test 'inheritance of curies' do
    decorator_a = Class.new do
      include HALDecorator
      def self.a; "A"; end
      curie :a { a << "#{options[:b] && b}" << "#{options[:c] && c}" }
    end

    decorator_b = Class.new(decorator_a) do
      def self.b; "B"; end
      curie :b { b }
      curie :x { "#{a}" }
    end

    decorator_c = Class.new(decorator_b) do
      def self.c; "C"; end
      curie :b, 'bc'
      curie :c { c }
      curie :y { "#{a}#{b}" }
    end

    decorator_a.to_hal(nil).tap do |payload|
      assert_sameish_hash(
        {
          _links: {
            curies: [
              {
                name: 'a',
                href: 'A',
                templated: true
              }
            ]
          }
        },
        JSON.parse(payload)
      )
    end

    decorator_b.to_hal(nil).tap do |payload|
      assert_sameish_hash(
        {
          _links: {
            curies: [
              {
                name: 'a',
                href: 'A',
                templated: true
              },
              {
                name: 'b',
                href: 'B',
                templated: true
              },
              {
                name: 'x',
                href: 'A',
                templated: true
              }
            ]
          }
        },
        JSON.parse(payload)
      )
    end

    decorator_c.to_hal(nil, {c: true}).tap do |payload|
      assert_sameish_hash(
        {
          _links: {
            curies: [
              {
                name: 'a',
                href: 'AC',
                templated: true
              },
              {
                name: 'x',
                href: 'A',
                templated: true
              },
              {
                name: 'b',
                href: 'bc',
                templated: true
              },
              {
                name: 'c',
                href: 'C',
                templated: true
              },
              {
                name: 'y',
                href: 'AB',
                templated: true
              }
            ]
          }
        },
        JSON.parse(payload)
      )
    end
  end

  test 'inheritance of embedded' do
    decorator_a = Class.new do
      include HALDecorator
      embed :r, decorator_class: ChildDecorator
    end

    decorator_b = Class.new(decorator_a) do
      embed :b, decorator_class: ChildDecorator
    end

    decorator_c = Class.new(decorator_b) do
      embed :r, decorator_class: ParentDecorator
    end

    obj = OpenStruct.new(
      to_be: 'ignored',
      r: Child.new(:child_r, :child_r_data),
      b: Child.new(:child_b, :child_b_data)
    )

    decorator_a.to_hal(obj).tap do |payload|
      assert_sameish_hash(
        {
          _embedded: {
            r:  {
              data: "child_r_data"
            }
          }
        },
        JSON.parse(payload)
      )
    end

    decorator_b.to_hal(obj).tap do |payload|
      assert_sameish_hash(
        {
          _embedded: {
            r:  {
              data: "child_r_data"
            },
            b:  {
              data: "child_b_data"
            }
          }
        },
        JSON.parse(payload)
      )
    end

    decorator_c.to_hal(obj).tap do |payload|
      assert_sameish_hash(
        {
          _embedded: {
            r:  {
              title: "child_r"
            },
            b:  {
              data: "child_b_data"
            }
          }
        },
        JSON.parse(payload)
      )
    end
  end

end
