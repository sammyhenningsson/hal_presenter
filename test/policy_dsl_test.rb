require 'test_helper'
require 'ostruct'

class PolicyDSLTest < ActiveSupport::TestCase

  def setup
    @policy = Class.new do
      include HALDecorator::Policy::DSL
      def default(current_user)
        current_user&.name == 'bengt'
      end
    end
    @user = OpenStruct.new(name: 'bengt')
    @resource = OpenStruct.new(title: 'hello')
  end

  test 'allow_by_default' do
    @policy.allow_by_default :attributes, :embedded

    policy = @policy.new(@user, @resource)
    assert_equal true, policy.attribute?(:name)
    assert_equal false, policy.link?(:delete)
    assert_equal true, policy.embed?(:delete)
  end

  test 'attribute' do
    @policy.attribute :name do
      current_user.name == 'bengt'
    end

    @policy.attribute :password do
      resource.title && false
    end

    @policy.attribute :comment

    policy = @policy.new(@user, @resource)
    assert_equal true, policy.attribute?(:name)
    assert_equal false, policy.attribute?(:password)
    assert_equal true, policy.attribute?(:comment)
  end
    
  test 'link' do
    @policy.link :self do
      current_user.name == 'bengt'
    end

    @policy.link :edit do
      resource.title && false
    end

    policy = @policy.new(@user, @resource)
    assert_equal true, policy.link?(:self)
    assert_equal false, policy.link?(:edit)
  end

  test 'embed' do
    @policy.embed :parent do
      current_user.name == 'bengt'
    end

    @policy.embed :child do
      resource.title && false
    end

    policy = @policy.new(@user, @resource)
    assert_equal true, policy.embed?(:parent)
    assert_equal false, policy.embed?(:child)
  end

  test 'multiple' do
    @policy.attribute :name, :password do
      default(current_user)
    end

    @policy.link :self, :edit do
      default(current_user)
    end

    @policy.embed :child1, :child2

    policy = @policy.new(@user, @resource)
    assert_equal true, policy.attribute?(:name)
    assert_equal true, policy.attribute?(:password)
    assert_equal true, policy.link?(:self)
    assert_equal true, policy.link?(:edit)
    assert_equal true, policy.embed?(:child1)
    assert_equal true, policy.embed?(:child2)
  end
end
