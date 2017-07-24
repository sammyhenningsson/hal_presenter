require 'test_helper'
require 'ostruct'
require 'json'

class DeserializerTest < ActiveSupport::TestCase

  Model = Struct.new(:title, :comment, :other, :parent, :children)
  Association = Struct.new(:title)

  class AssociationDecorator
    include HALDecorator
    model Association

    attribute :title
  end

  class Decorator
    include HALDecorator
    model Model

    attribute :title
    attribute :comment
    attribute :extra

    embed :parent, decorator_class: AssociationDecorator
    embed :children, decorator_class: AssociationDecorator
  end

  def setup
    @json = JSON.generate({
      title: "the title",
      comment: "very good",
      other: "to be ignored",
      _embedded: {
        parent: {
          title: :some_parent
        },
        children: [
          {
			title: :child1,
            data: :child1_data
          },
          {
			title: :child2,
            data: :child2_data
          }
        ]
      }
    })
  end

  test "HALDecorator.from_hal" do
    resource = HALDecorator.from_hal(Decorator, @json)
    assert resource
    assert_equal Model, resource.class
    assert_equal "very good", resource.comment
    assert_nil resource.other
    assert resource.parent
    assert_equal "some_parent", resource.parent.title
    assert resource.children
    assert_equal 2, resource.children.size
    assert_equal "child1", resource.children[0].title
    assert_equal "child2", resource.children[1].title
  end

  test "Decorator.from_hal" do
    resource = Decorator.from_hal(@json)
    assert resource
    assert_equal Model, resource.class
    assert_equal "very good", resource.comment
  end
end

