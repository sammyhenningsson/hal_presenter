require 'test_helper'
require 'ostruct'
require 'json'

class DeserializerTest < ActiveSupport::TestCase

  Model = Struct.new(:title, :comment, :other, :parent, :children)
  Association = Struct.new(:title)

  class AssociationPresenter
    extend HALPresenter
    model Association

    attribute :title
  end

  class Presenter
    extend HALPresenter
    model Model

    attribute :title
    attribute :comment
    attribute :extra

    embed :parent, presenter_class: AssociationPresenter
    embed :children, presenter_class: AssociationPresenter
  end

  def setup
    @json = JSON.generate({
      title: 'the title',
      comment: 'very good',
      other: 'to be ignored',
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

  test 'HALPresenter.from_hal' do
    resource = HALPresenter.from_hal(Presenter, @json)
    assert resource
    assert_equal Model, resource.class
    assert_equal 'very good', resource.comment
    assert_nil resource.other
    assert resource.parent
    assert_equal 'some_parent', resource.parent.title
    assert resource.children
    assert_equal 2, resource.children.size
    assert_equal 'child1', resource.children[0].title
    assert_equal 'child2', resource.children[1].title
  end

  test 'Presenter.from_hal' do
    resource = Presenter.from_hal(@json)
    assert resource
    assert_instance_of Model, resource
    assert_equal 'very good', resource.comment
  end

  test 'Deserialize into existing resource' do
    resource = Model.new(
      'title',
      'to_be_changed',
      nil,
      OpenStruct.new(title: 'to_be_changed')
    )
    Presenter.from_hal(@json, resource)
    assert resource
    assert_instance_of Model, resource
    assert_equal 'very good', resource.comment
    parent = resource.parent
    assert_instance_of OpenStruct, parent
    assert_equal 'some_parent', parent.title
  end

  test 'empty payload returns nil' do
    assert_nil Presenter.from_hal(nil)
    assert_nil Presenter.from_hal("")
  end
end
