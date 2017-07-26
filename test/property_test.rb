require 'test_helper'

Struct.new('Item', :name, :color)

class PropertyTest < ActiveSupport::TestCase
  def setup
    @item = Struct::Item.new('car', 'green')
  end

  test 'that value is returned from property' do
    property = HALDecorator::Property.new(:name, 'bicycle')
    assert_equal('bicycle', property.value)
    assert_equal('bicycle', property.value(@item))
  end

  test 'that value is returned from item' do
    property = HALDecorator::Property.new(:name)
    assert_equal('car', property.value(@item))
  end

  test 'that value is returned from block' do
    property = HALDecorator::Property.new(:name) { 'bus' }
    assert_equal('bus', property.value(@item))
  end

  test 'that resource is accessible in block' do
    property = HALDecorator::Property.new(:name) { resource.color }
    assert_equal('green', property.value(@item))
  end

  test 'that options is accessible in block' do
    opts = { default_value: 'blue' }
    property = HALDecorator::Property.new(:name) { options[:default_value] }
    assert_equal('blue', property.value(@item, opts))
  end

  test 'that resource/options are not reused' do
    opts1 = { default_value: 'blue' }
    opts2 = { default_value: 'black' }
    item2 = Struct::Item.new('bus', 'white')

    property = HALDecorator::Property.new(:name) do
      [resource.name, options[:default_value]]
    end

    assert_equal(%w[car blue], property.value(@item, opts1))
    assert_equal(%w[bus black], property.value(item2, opts2))
  end

  test 'block can access methods from block creation scope' do
    def decorator_foo(arg)
      x = yield if block_given?
      "#{arg}_#{x}"
    end
    property = HALDecorator::Property.new(:name) do
      decorator_foo('something') { 'complex' }
    end
    assert_equal('something_complex', property.value)
  end
end
