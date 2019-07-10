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

  class ParentPresenter
    extend HALPresenter

    attribute :title
  end

  class ChildPresenter
    extend HALPresenter
    model Child

    attribute :data do
      options[:child_data] || resource.data
    end
  end

  class Presenter
    extend HALPresenter

    attribute :title
    attribute :comment
    link :self do
      "/items/#{resource.id}"
    end
    link :edit, title: 'Redigera' do
      options[:edit_uri] || '/items/5/edit'
    end
    link :'doc:user', '/some/uri/with/namespace'
    curie :'doc', '/some/templated/uri/{rel}'
    embed :parent, presenter_class: ParentPresenter
    embed :children, presenter_class: ChildPresenter
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
      comment: 'some comments',
      extra: 'lorem ipsum',
      parent: parent,
      children: [child1, child2]
    )

    @expected = {
      title: 'some_title',
      comment: 'some comments',
      _links: {
        self: {
          href: '/items/5'
        },
        edit: {
          href: '/items/5/edit',
          title: 'Redigera',
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

  test 'HALPresenter.to_hal' do
    options = { presenter: Presenter }
    payload = HALPresenter.to_hal(@obj, options)
    assert_sameish_hash(@expected, JSON.parse(payload))
  end

  test 'Presenter.to_hal' do
    payload = Presenter.to_hal(@obj)
    assert_sameish_hash(@expected, JSON.parse(payload))
  end

  test 'Policy is honored (and curies are shown)' do
    class Policy
      def initialize(*); end

      def attribute?(attribute)
        attribute == :title
      end

      def link?(rel)
        rel == :self
      end

      def embed?(name)
        name == :parent
      end
    end

    class PolicyPresenter < Presenter
      policy Policy
    end

    expected = {
      title: 'some_title',
      _links: {
        self: {
          href: '/items/5'
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
        }
      }
    }

    payload = PolicyPresenter.to_hal(@obj)
    assert_sameish_hash(expected, JSON.parse(payload))
  end

  test 'Serialize full links with Presenter.base_href' do
    HALPresenter.base_href = 'https://example.com/'
    @expected[:_links].each do |key, value|
      if key == :curies
        value.each { |curie| curie[:href].prepend('https://example.com') }
      else
        value[:href].prepend 'https://example.com'
      end
    end

    begin
      payload = Presenter.to_hal(@obj)
    ensure
      HALPresenter.base_href = nil
    end
    assert_sameish_hash(@expected, JSON.parse(payload))
  end

  test 'Presenter.to_hal with options' do
    options = { edit_uri: 'foo', child_data: 'optional_data' }
    payload = Presenter.to_hal(@obj, options)
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
      ChildPresenter.to_hal(obj)
    end
  end

  test 'multiple nested embeds' do
    c = Class.new do
      extend HALPresenter
      link :self, '/grandchild'
      link :foo, '/grand_foo', embed_depth: 1
      curie :c, '/c/{rel}'
      curie :a, '/a/{rel}'
      attribute :data
      attribute :c, 'c', embed_depth: 2
      attribute :c0, 'c0', embed_depth: 0
      attribute :c1, 'c1', embed_depth: 1
      attribute :c2, 'c2', embed_depth: 2
      attribute :c3, 'c3', embed_depth: 3
    end
    b = Class.new do
      extend HALPresenter
      link :self, '/child'
      link :foo, '/foo', embed_depth: 1
      curie :b, '/b/{rel}'
      attribute :data
      attribute :b0, 'b0', embed_depth: 0
      attribute :b1, 'b1', embed_depth: 1
      attribute :b2, 'b2', embed_depth: 2
      embed :child, presenter_class: c

    end
    a = Class.new do
      extend HALPresenter
      link :self, '/'
      curie :a, '/a/{rel}'
      attribute :data
      attribute :a0, 'a0', embed_depth: 0
      embed :child, presenter_class: b, embed_depth: nil
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
      a0: 'a0',
      _links: {
        self: {
          href: '/'
        },
        curies: [
          {
            name: 'a',
            href: '/a/{rel}',
            templated: true
          },
          {
            name: 'b',
            href: '/b/{rel}',
            templated: true
          },
          {
            name: 'c',
            href: '/c/{rel}',
            templated: true
          }
        ]
      },
      _embedded: {
        child: {
          data: 'child',
          b1: 'b1',
          b2: 'b2',
          _links: {
            self: {
              href: '/child'
            },
            foo: {
              href: '/foo'
            }
          },
          _embedded: {
            child: {
              data: 'grandchild',
              c: 'c',
              c2: 'c2',
              c3: 'c3',
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

  test 'subclasses of a registered model will use the same presenter' do
    grand_child_class = Class.new(Child)
    grand_child = grand_child_class.new('title', 'some data')
    HALPresenter.to_hal(grand_child).tap do |payload|
      assert_sameish_hash(
        {
          data: 'some data'
        },
        JSON.parse(payload)
      )
    end
  end

  test 'inheritance of model' do
    foo = Class.new(Child) do
      def f; 'F'; end
    end

    presenter_a = Class.new(ChildPresenter) do
      attribute :a, 'A'
    end

    Class.new(presenter_a) do
      model foo
      attribute :f
    end

    child = Child.new(:child1, :child1_data)
    foo = foo.new(:foo1, :foo1_data)

    HALPresenter.to_hal(child).tap do |payload|
      assert_sameish_hash(
        {
          data: 'child1_data',
          a: 'A'
        },
        JSON.parse(payload)
      )
    end

    HALPresenter.to_hal(foo).tap do |payload|
      assert_sameish_hash(
        {
          data: 'foo1_data',
          a: 'A',
          f: 'F'
        },
        JSON.parse(payload)
      )
    end

    # CLeanup
    HALPresenter.unregister(presenter_a)
  end

  test 'inheritance of attributes' do
    presenter_a = Class.new do
      extend HALPresenter
      def self.a; "A"; end
      attribute(:a) { a << "#{options[:b] && b}" << "#{options[:c] && c}" }
    end

    presenter_b = Class.new(presenter_a) do
      def self.b; "B"; end
      attribute(:b) { b }
      attribute(:x) { "#{a}" }
    end

    presenter_c = Class.new(presenter_b) do
      def self.c; "C"; end
      attribute(:b, 'bc')
      attribute(:c) { c }
      attribute(:y) { "#{a}#{b}" }
    end

    presenter_a.to_hal(nil).tap do |payload|
      assert_sameish_hash({a: 'A'}, JSON.parse(payload))
    end

    presenter_b.to_hal(nil).tap do |payload|
      assert_sameish_hash({a: 'A', b: 'B', x: 'A'}, JSON.parse(payload))
    end

    presenter_c.to_hal(nil, {c: true}).tap do |payload|
      assert_sameish_hash({a: 'AC', b: 'bc', c: 'C', x: 'A', y: 'AB'}, JSON.parse(payload))
    end
  end

  test 'inheritance of links' do
    presenter_a = Class.new do
      extend HALPresenter
      def self.a; "A"; end
      link(:a) { a << "#{options[:b] && b}" << "#{options[:c] && c}" }
    end

    presenter_b = Class.new(presenter_a) do
      def self.b; "B"; end
      link(:b) { b }
      link(:x) { "#{a}" }
    end

    presenter_c = Class.new(presenter_b) do
      def self.a; "C"; end
      def self.c; "C"; end
      link(:b, 'bc')
      link(:c) { c }
      link(:y) { "#{a}#{b}" }
    end

    presenter_a.to_hal(nil).tap do |payload|
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

    presenter_b.to_hal(nil).tap do |payload|
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

    presenter_c.to_hal(nil, {c: true}).tap do |payload|
      assert_sameish_hash(
        {
          _links: {
            a: {
              href: 'CC'
            },
            b: {
              href: 'bc'
            },
            c: {
              href: 'C'
            },
            x: {
              href: 'C'
            },
            y: {
              href: 'CB'
            }
          }
        },
        JSON.parse(payload)
      )
    end
  end

  test 'inheritance of curies' do
    presenter_a = Class.new do
      extend HALPresenter
      def self.a; "A"; end
      curie(:a) { a << "#{options[:b] && b}" << "#{options[:c] && c}" }
    end

    presenter_b = Class.new(presenter_a) do
      def self.b; "B"; end
      curie(:b) { b }
      curie(:x) { "#{a}" }
    end

    presenter_c = Class.new(presenter_b) do
      def self.c; "C"; end
      curie(:b, 'bc')
      curie(:c) { c }
      curie(:y) { "#{a}#{b}" }
    end

    presenter_a.to_hal(nil).tap do |payload|
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

    presenter_b.to_hal(nil).tap do |payload|
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

    presenter_c.to_hal(nil, {c: true}).tap do |payload|
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
    presenter_a = Class.new do
      extend HALPresenter
      embed :r, presenter_class: ChildPresenter
    end

    presenter_b = Class.new(presenter_a) do
      embed :b, presenter_class: ChildPresenter
    end

    presenter_c = Class.new(presenter_b) do
      embed :r, presenter_class: ParentPresenter
    end

    obj = OpenStruct.new(
      to_be: 'ignored',
      r: Child.new(:child_r, :child_r_data),
      b: Child.new(:child_b, :child_b_data)
    )

    presenter_a.to_hal(obj).tap do |payload|
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

    presenter_b.to_hal(obj).tap do |payload|
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

    presenter_c.to_hal(obj).tap do |payload|
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
