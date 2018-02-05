## 0.4.1
 * Policies created with HALDecorator::Policy::DSL now always allows links with rel `self`.
 * Policy is now used in collection blocks as well.
 * Make serializer class methods available in collection block (through method_missing).
 * Support `embed` in collection blocks.
 * Fix broken backwards compatibility with `decorator_class` as kw arg to `embed`.
## 0.4.0
 * Renaming Decorator to Presenter
 * Pass serializer options to Policy
## 0.3.6
 * Deprecate this gem and refer to HALPresenter
## 0.3.4
 * Support pagination.
 * Embedded arrays will now be serialized as a collection if the serializer has a collection.
## 0.3.3
 * Declare multiple attributes, links or embeds with the same rule in HALDecorator::Policy::DSL.
## 0.3.2
 * Allow properties without specifying a block in HALDecorator::Policy::DSL.
 * Added `allow_by_default` to HALDecorator::Policy::DSL.
## 0.3.1
 * Classes should now extend HALDecorator instead of include it.
 * Support inheritance of Serializers.
 * Add config for setting a base uri that will get prepended to link hrefs.
 * Add method `post_serialize`
