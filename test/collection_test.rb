require 'test_helper'
require 'ostruct'

class CollectionTest < ActiveSupport::TestCase

  Resource = Struct.new(:id, :title, :data)

  class Decorator
    include HALDecorator
    model Resource

    attribute :title
    attribute :data
    link :self do |object|
      "/resources/#{object.id}"
    end

    collection do
      name 'resources'
    end
  end

  def setup
    @resources = (1..3).map do |i|
      Resource.new(i, "title#{i}", "data#{i}")
    end
  end

  test "serialize" do
    payload = HALDecorator.to_hal_collection(@resources)
    assert_equal(
      JSON.generate(
        {
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
      ),
      payload
    )
  end
end

