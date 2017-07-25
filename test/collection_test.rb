require 'test_helper'
require 'ostruct'

class CollectionTest < ActiveSupport::TestCase

  Resource = Struct.new(:id, :title, :data)

  class Decorator
    include HALDecorator
    model Resource

    attribute :title
    attribute :data
    link :self do
      "/resources/#{object.id}"
    end

    as_collection_of 'resources'
  end

  def setup
    @resources = (1..3).map do |i|
      Resource.new(i, "title#{i}", "data#{i}")
    end

    @expected = {
      _embedded: {
        resources: [
          {
            title: 'title1',
            data: 'data1',
            _links: {
              self: {
                href: '/resources/1'
              }
            }
          },
          {
            title: 'title2',
            data: 'data2',
            _links: {
              self: {
                href: '/resources/2'
              }
            }
          },
          {
            title: 'title3',
            data: 'data3',
            _links: {
              self: {
                href: '/resources/3'
              }
            }
          }
        ]
      }
    }
  end

  test 'HALDecorator.to_hal_collection' do
    payload = HALDecorator.to_hal_collection(@resources)
    assert_equal(JSON.generate(@expected), payload)
  end

  test 'HALDecorator.to_hal_collection with opts' do
    attributes = { collection_attribute: 'some_attribute' }
    links = {
      self: { href: '/resources?page=1' },
      next: { href: '/resources?page=2' }
    }
    payload = HALDecorator.to_hal_collection(@resources, attributes: attributes, links: links)
    @expected[:collection_attribute] = 'some_attribute'
    @expected[:links] = {
      self: { href: '/resources?page=1' },
      next: { href: '/resources?page=2' }
    }
    assert_equal(@expected, JSON.parse(payload))
  end
end
