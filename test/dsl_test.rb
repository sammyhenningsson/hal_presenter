require 'test_helper'
require 'ostruct'

class DSLTest < ActiveSupport::TestCase
  def setup
    @obj = OpenStruct.new(
      from_object: 'string_from_obj'.freeze,
      from_block: 'string_from_block'.freeze
    )
    @serializer = Class.new { include HALDecorator }
  end

  test 'model' do
    Model = Struct.new(:title)
    @serializer.model Model
    resource = Model.new(title: 'some title')
    assert_equal @serializer, HALDecorator.lookup_decorator(resource).first
  end

  test 'attribute with value from contant' do
    @serializer.attribute :from_constant, 'some_string'.freeze
    attribute = @serializer.attributes.first
    assert_instance_of HALDecorator::Property, attribute
    assert_equal :from_constant, attribute.name
    assert_equal 'some_string' , attribute.value('ignore'.freeze)
  end

  test 'attribute with value from object' do
    @serializer.attribute :from_object
    attribute = @serializer.attributes.first
    assert_instance_of HALDecorator::Property, attribute
    assert_equal :from_object, attribute.name
    assert_equal 'string_from_obj', attribute.value(@obj)
  end

  test 'attribute with value from block' do
    @serializer.attribute :from_block { resource.from_block }
    attribute = @serializer.attributes.first
    assert_instance_of HALDecorator::Property, attribute
    assert_equal :from_block, attribute.name
    assert_equal 'string_from_block' , attribute.value(@obj)
  end

  test 'link with value from contant' do
    @serializer.link :from_constant, 'some_string'.freeze
    link = @serializer.links.last
    assert_instance_of HALDecorator::Links::Link, link
    assert_equal :from_constant, link.name
    assert_equal 'some_string' , link.value('ignore'.freeze)
  end

  test 'link with value from block' do
    @serializer.link :from_block { resource.from_block }
    link = @serializer.links.first
    assert_instance_of HALDecorator::Links::Link, link
    assert_equal :from_block, link.name
    assert_equal 'string_from_block' , link.value(@obj)
  end

  test 'link with http method' do
    @serializer.link :with_method, method: :put { 'resource/1/edit' }
    link = @serializer.links.first
    assert_instance_of HALDecorator::Links::Link, link
    assert_equal :with_method, link.name
    assert_equal 'resource/1/edit' , link.value(@obj)
    assert_equal :put, link.http_method
  end

  test 'link must have a constant or block' do
    assert_raises RuntimeError do
      @serializer.link :no_good
    end
  end

  test 'curie with value from contant' do
    @serializer.curie :from_constant, 'some_string'.freeze
    curie = @serializer.curies.last
    assert_instance_of HALDecorator::Property, curie
    assert_equal :from_constant, curie.name
    assert_equal 'some_string' , curie.value('ignore'.freeze)
  end

  test 'curie with value from block' do
    @serializer.curie :from_block { resource.from_block }
    curie = @serializer.curies.first
    assert_instance_of HALDecorator::Property, curie
    assert_equal :from_block, curie.name
    assert_equal 'string_from_block' , curie.value(@obj)
  end

  test 'curie must have a constant or block' do
    assert_raises RuntimeError do
      @serializer.curie :no_good
    end
  end

  test 'embed with value from contant' do
    @serializer.embed :from_constant, OpenStruct.new(title: 'from_constant').freeze
    embed = @serializer.embedded.first
    assert_instance_of HALDecorator::Embedded::Embed, embed
    assert_equal :from_constant, embed.name
    assert_instance_of OpenStruct , embed.value('ignored'.freeze)
    assert_equal 'from_constant', embed.value.title
  end

  test 'embed with value from object' do
    @serializer.embed :from_object
    embed = @serializer.embedded.first
    assert_instance_of HALDecorator::Embedded::Embed, embed
    assert_equal :from_object, embed.name
    assert_equal 'string_from_obj', embed.value(@obj)
  end

  test 'embed with value from block' do
    @serializer.embed :from_block do
      resource.from_block
    end
    embed = @serializer.embedded.first
    assert_instance_of HALDecorator::Embedded::Embed, embed
    assert_equal :from_block, embed.name
    assert_equal 'string_from_block' , embed.value(@obj)
  end

  test 'embed with specified decorator' do
    EmbeddedSerializer = Struct.new(:name)
    @serializer.embed :from_block, decorator_class: EmbeddedSerializer do
      {foo: 2}
    end
    embed = @serializer.embedded.first
    assert_instance_of HALDecorator::Embedded::Embed, embed
    assert_equal :from_block, embed.name
    assert_equal({foo: 2}, embed.value)
    assert_equal EmbeddedSerializer, embed.decorator_class
  end

  test 'collection with block' do
    @serializer.collection of: 'items' do
      attribute :collection_attribute
      link :collection_link, '/'
      curie :collection_curie, '/'
    end

    collection = @serializer.collection_parameters
    assert collection
    assert_equal 'items', collection.name
    assert_equal 1, collection.attributes.size
    assert_equal 1, collection.links.size
    assert_equal 1, collection.curies.size
  end

  test 'collection must have a "of" keyword argument' do
    assert_raises ArgumentError do
      @serializer.collection do
        attribute :collection_attribute
      end
    end

  end
end
