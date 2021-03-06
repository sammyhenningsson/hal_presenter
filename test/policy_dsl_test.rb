require 'test_helper'
require 'ostruct'

class PolicyDSLTest < ActiveSupport::TestCase

  def setup
    @policy = Class.new do
      include HALPresenter::Policy::DSL
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

  test 'inheritance' do
    @policy.attribute :foo
    @policy.link :bar
    @policy.embed :baz

    @policy.attribute :to_be_overridden
    @policy.link :to_be_overridden
    @policy.embed :to_be_overridden

    @policy.define_method :authenticated? do
      options[:authenticated]
    end

    child_policy_class = Class.new(@policy)

    child_policy_class.attribute(:to_be_overridden) { false }
    child_policy_class.link(:to_be_overridden) { false }
    child_policy_class.embed(:to_be_overridden) { false }

    policy = child_policy_class.new(@user, @resource, authenticated: :yes)
    assert_equal true, policy.attribute?(:foo)
    assert_equal true, policy.link?(:bar)
    assert_equal true, policy.embed?(:baz)

    assert_equal false, policy.attribute?(:to_be_overridden)
    assert_equal false, policy.link?(:to_be_overridden)
    assert_equal false, policy.embed?(:to_be_overridden)

    assert_equal :yes, policy.authenticated?
  end

  test '#delegate_attribute' do
    policy_class = Class.new do
      include HALPresenter::Policy::DSL

      attribute :bar do
        resource.title == 'hello'
      end
    end

    @policy.attribute :foo do
      delegate_attribute policy_class, :bar
    end

    policy = @policy.new(@user, @resource)
    assert policy.attribute?(:foo)
  end

  test '#delegate_link' do
    policy_class = Class.new do
      include HALPresenter::Policy::DSL

      link :bar do
        resource == 1337
      end
    end

    @policy.link :foo do
      delegate_link policy_class, :bar, resource: 1337
    end

    policy = @policy.new(@user, @resource)
    assert policy.link?(:foo)
  end

  test '#delegate_to method' do
    policy_class = Class.new do
      include HALPresenter::Policy::DSL

      def baz
        options[:foobar] == '1337'
      end
    end

    @policy.attribute :foo do
      delegate_to policy_class, :baz, foobar: '1337'
    end

    policy = @policy.new(@user, @resource)
    assert policy.attribute?(:foo)
  end
end
