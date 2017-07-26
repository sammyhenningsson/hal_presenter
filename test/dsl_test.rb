require 'test_helper'
require 'ostruct'

class DSLTest < ActiveSupport::TestCase
  def setup
    @obj = OpenStruct.new(
      from_object: 'string_from_obj'.freeze,
      from_block: 'string_from_block'.freeze
    )
  end

  test 'model' do
    Model = Struct.new(:title)

    class Decorator
      include HALDecorator
      model Model
    end

    resource = Model.new(title: 'some title')
    assert_equal Decorator, HALDecorator.lookup_decorator(resource).first
  end

  test 'attributes' do
    class Decorator
      include HALDecorator

      attribute :from_constant, 'some_string'.freeze
      attribute :from_object
      attribute :from_block do
        resource.from_block
      end
    end

    attributes = Decorator.attributes
    assert attributes
    assert_equal 3, attributes.size

    attribute = attributes.shift
    assert_equal :from_constant, attribute.name
    assert_equal 'some_string' , attribute.value('foo'.freeze)

    attribute = attributes.shift
    assert_equal :from_object, attribute.name
    assert_equal 'string_from_obj', attribute.value(@obj)

    attribute = attributes.shift
    assert_equal :from_block, attribute.name
    assert_equal 'string_from_block' , attribute.value(@obj)

    assert_equal 3, Decorator.attributes.size
  end

  test 'links' do
    class Decorator
      include HALDecorator

      link :from_constant, 'some_string'.freeze
      link :from_block do
        resource.from_block
      end
      link :with_method, method: :put do
        'resource/1/edit'
      end
    end

    links = Decorator.links
    assert links
    assert_equal 3, links.size

    link = links.shift
    assert_equal :from_constant, link.name
    assert_equal 'some_string' , link.value('foo'.freeze)

    link = links.shift
    assert_equal :from_block, link.name
    assert_equal 'string_from_block' , link.value(@obj)

    link = links.shift
    assert_equal :with_method, link.name
    assert_equal 'resource/1/edit' , link.value(@obj)
    assert_equal :put, link.http_method

    assert_equal 3, Decorator.links.size
  end

  test 'curies' do
    class Decorator
      include HALDecorator

      curie :from_constant, 'some_string'.freeze
      curie :from_block do
        resource.from_block
      end
    end

    curies = Decorator.curies
    assert curies
    assert_equal 2, curies.size

    curie = curies.shift
    assert_equal :from_constant, curie.name
    assert_equal 'some_string' , curie.value('foo'.freeze)

    curie = curies.shift
    assert_equal :from_block, curie.name
    assert_equal 'string_from_block' , curie.value(@obj)

    assert_equal 2, Decorator.curies.size
  end

  test 'embbeded' do
    EmbeddedDecorator = Struct.new(:name)
    class Decorator
      include HALDecorator

      embed :from_constant, OpenStruct.new(title: 'from_constant').freeze, decorator_class: EmbeddedDecorator
      embed :from_object, decorator_class: EmbeddedDecorator
      embed :from_block, decorator_class: EmbeddedDecorator do
        resource.from_block
      end
    end

    embedded = Decorator.embedded
    assert embedded
    assert_equal 3, embedded.size

    embed = embedded.shift
    assert_equal :from_constant, embed.name
    assert_instance_of OpenStruct , embed.value('foo'.freeze)
    assert_equal 'from_constant', embed.value('foo'.freeze).title

    embed = embedded.shift
    assert_equal :from_object, embed.name
    assert_equal 'string_from_obj', embed.value(@obj)
    assert_equal EmbeddedDecorator, embed.decorator_class

    embed = embedded.shift
    assert_equal :from_block, embed.name
    assert_equal 'string_from_block' , embed.value(@obj)

    assert_equal 3, Decorator.embedded.size
  end

end

