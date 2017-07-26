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
      "/resources/#{resource.id}"
    end

    as_collection of: 'resources' do
      attribute :count

      link :self do
        '/resources?page=1'
      end

      link :next do
        return unless options.key? :page
        "/resources?page=#{options[:page]}"
      end
    end
  end

  def setup
    @resources = (1..3).map do |i|
      Resource.new(i, "title#{i}", "data#{i}")
    end

    @expected = {
      count: 3,
      _links: {
        self: {
          href: '/resources?page=1'
        }
      },
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

  test 'HALDecorator.to_collection' do
    payload = HALDecorator.to_collection(@resources)
    assert_sameish_hash(@expected, JSON.parse(payload))
  end

  test 'HALDecorator.to_collection with opts' do
    options = { page: 2 }
    payload = HALDecorator.to_collection(@resources, options)
    @expected[:_links][:next] = { href: '/resources?page=2' }
    assert_sameish_hash(@expected, JSON.parse(payload))
  end
end
