require 'test_helper'

class PolicyTest < ActiveSupport::TestCase

  def setup
    @serializer = Class.new { extend HALDecorator }
  end

  test 'policy inheritance' do
    p = Class.new
    @serializer.policy p

    serializer1 = Class.new(@serializer)
    assert_equal p, serializer1.send(:policy_class)
  end

  test 'inherited serializer can override policy' do

    some_policy = Class.new
    serializer2 = Class.new(@serializer) do
      policy some_policy
    end
    assert_equal some_policy, serializer2.send(:policy_class)
  end
end
