require 'test_helper'
require 'ostruct'

class SerializerTest < ActiveSupport::TestCase

  class EmbeddedDecorator
    include HALDecorator

    attribute :title
  end

  class Decorator
    include HALDecorator

    attribute :title
    link :self, "/some/uri"
    link :'doc:user', "/some/uri/with/namespace"
    curie :'doc', "/some/templated/uri/{rel}"
    embed :parent, decorator_class: EmbeddedDecorator
    embed :children, decorator_class: EmbeddedDecorator
  end

  def setup

    parent = OpenStruct.new(
      title: :some_parent,
      data: :parent_data
    )

    child1 = OpenStruct.new(
      title: :child1,
      data: :child1_data
    )

    child2 = OpenStruct.new(
      title: :child2,
      data: :child2_data
    )

    @obj = OpenStruct.new(
      title: "some_title",
      comment: "some_comments",
      parent: parent,
      children: [child1, child2]
    )

  end

  test "serialize" do
    serialized = Decorator.to_hash(@obj)
    assert_equal(
      {
        title: "some_title",
        _links: {
          self: {
            href: "/some/uri"
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
              title: :child1
            },
            {
              title: :child2
            }
          ]
        }
      },
      serialized
    )
  end
end
