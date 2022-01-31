require 'test_helper'
require 'ostruct'

module HALPresenter
  describe Links do
    it 'block can return a hash with values' do
      object = OpenStruct.new(id: 5, title: "Hello Foo")
      link = Link.new :my_rel do
        {
          href: "https://resources/#{resource.id}{?query}",
          deprecated: "Deprecated: ...",
          type: "Foo",
          profile: "FooProfile",
          title: resource.title,
          templated: true,
        }
      end

      hash = link.to_h(object)

      assert_equal(
        {
          href: "https://resources/5{?query}",
          deprecated: "Deprecated: ...",
          type: "Foo",
          profile: "FooProfile",
          title: "Hello Foo",
          templated: true,
        },
        hash
      )
    end
  end
end
