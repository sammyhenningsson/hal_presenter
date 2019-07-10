require 'test_helper'

class NamespaceTest < ActiveSupport::TestCase
  test 'links can be in namspaces' do
    presenter_a = Class.new do
      extend HALPresenter

      namespace :foo do
        link :bar, '/foobar'
        link :baz, '/baz'
      end

      curie :foo, '/foo/{rel}'
    end

    presenter_a.to_hal(nil).tap do |payload|
      assert_sameish_hash(
        {
          _links: {
            'foo:bar': {
              href: '/foobar'
            },
            'foo:baz': {
              href: '/baz'
            },
            curies: [
              {
                name: 'foo',
                href: '/foo/{rel}',
                templated: true
              }
            ]
          }
        },
        JSON.parse(payload)
      )
    end
  end

  test 'embedded resources can be in namspaces' do
    embed_presenter = Class.new do
      extend HALPresenter

      attribute :hello, 'world'
    end

    presenter_a = Class.new do
      extend HALPresenter

      namespace :foo do
        embed :bar, 'not_used', presenter_class: embed_presenter
        embed :baz, 'not_used', presenter_class: embed_presenter
      end

      curie :foo, '/foo/{rel}'
    end

    presenter_a.to_hal(nil).tap do |payload|
      assert_sameish_hash(
        {
          _links: {
            curies: [
              {
                name: 'foo',
                href: '/foo/{rel}',
                templated: true
              }
            ]
          },
          _embedded: {
            'foo:bar': {
              hello: 'world'
            },
            'foo:baz': {
              hello: 'world'
            }
          }
        },
        JSON.parse(payload)
      )
    end
  end
end
