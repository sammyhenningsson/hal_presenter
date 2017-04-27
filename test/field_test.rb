require 'test_helper'

Struct.new("Item", :name, :color)

class FieldTest < ActiveSupport::TestCase

  def setup
    @item = Struct::Item.new("car", "green")
  end

  test "that value is returned from field" do
    field = HALDecorator::Field.new(:name, "bicycle").freeze
    assert_equal("bicycle", field.value(@item))
  end

  test "that value is returned from object" do
    field = HALDecorator::Field.new(:name).freeze
    assert_equal("car", field.value(@item))
  end

  test "that value is returned from block" do
    field = HALDecorator::Field.new(:name) do |object|
      "bus"
    end
    field.freeze
    assert_equal("bus", field.value(@item))
  end

  test "that object is accessible in block" do
    field = HALDecorator::Field.new(:name) do |object|
      object.color
    end
    field.freeze
    assert_equal("green", field.value(@item))
  end

end
