require 'test_helper'

Struct.new("Item", :name, :color)

class PropertyTest < ActiveSupport::TestCase

  def setup
    @item = Struct::Item.new("car", "green")
  end

  test "that value is returned from property" do
    property = HALDecorator::Property.new(:name, "bicycle").freeze
    assert_equal("bicycle", property.value(@item))
  end

  test "that value is returned from object" do
    property = HALDecorator::Property.new(:name).freeze
    assert_equal("car", property.value(@item))
  end

  test "that value is returned from block" do
    property = HALDecorator::Property.new(:name) do |object|
      "bus"
    end
    property.freeze
    assert_equal("bus", property.value(@item))
  end

  test "that object is accessible in block" do
    property = HALDecorator::Property.new(:name) do |object|
      object.color
    end
    property.freeze
    assert_equal("green", property.value(@item))
  end

end
