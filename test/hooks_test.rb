require 'test_helper'
require 'ostruct'

class HooksTest < ActiveSupport::TestCase

  class HooksPresenter
    extend HALPresenter

    attribute :title

    post_serialize do |hash|
      hash[:data] = resource.data
      hash[:option] = options[:data]
    end
  end

  def setup
    @item = OpenStruct.new(title: 'hooks', data: 'hello')

    @expected = {
      title: 'hooks',
      data:  'hello',
      option: 'world'
    }

    @options = { data: 'world' }
  end

  test 'HooksPresenter.to_hal with post serialize hook' do
    payload = HooksPresenter.to_hal(@item, @options)
    assert_sameish_hash(@expected, JSON.parse(payload))
  end

  test 'inheritance of post serialize hook' do
    presenter_a = Class.new(HooksPresenter) do
      attribute :a, 'A'
    end

    presenter_b = Class.new(presenter_a) do
      post_serialize do |hash|
        hash[:data] = 'overridden'
      end
    end

    presenter_a.to_hal(@item, @options).tap do |payload|
      @expected[:a] = 'A'
      assert_sameish_hash(
        @expected,
        JSON.parse(payload)
      )
    end

    presenter_b.to_hal(@item, @options).tap do |payload|
      assert_sameish_hash(
        {
          title: 'hooks',
          data: 'overridden',
          a: 'A'
        },
        JSON.parse(payload)
      )
    end
  end
end

