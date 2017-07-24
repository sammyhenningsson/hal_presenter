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

    attribute :data
  end

  class Decorator
    include HALDecorator

    attribute :title
    link :self, "/some/uri"
    link :edit, method: :put do
      "/some/uri/edit"
    end
    link :'doc:user', "/some/uri/with/namespace"
    curie :'doc', "/some/templated/uri/{rel}"
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
      title: "some_title",
      comment: "some_comments",
      parent: parent,
      children: [child1, child2]
    )

    @expected = JSON.generate(
      {
        title: "some_title",
        _links: {
          self: {
            href: "/some/uri"
          },
          edit: {
            href: "/some/uri/edit",
            method: 'put',
          },
          'doc:user': {
            href: "/some/uri/with/namespace"
          },
          curies: [
            {
              name: :doc,
              href: "/some/templated/uri/{rel}",
              templated: true
            }
          ],
        },
        _embedded: {
          parent: {
            title: :some_parent
          },
          children: [
            {
              data: :child1_data
            },
            {
              data: :child2_data
            }
          ]
        }
      }
    )
  end

  test "HALDecorator.to_hal" do
    payload = HALDecorator.to_hal(@obj, decorator: Decorator)
    assert_equal(@expected, payload)
  end

  test "Decorator.to_hal" do
    payload = Decorator.to_hal(@obj)
    assert_equal(@expected, payload)
  end

end
