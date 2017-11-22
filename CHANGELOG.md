## 0.3.4 / 2017-11-22
 * Support pagination.
 * Embedded arrays will now be serialized as a collection if the serializer has a collection.
## 0.3.3 / 2017-09-10
 * Declare multiple attributes, links or embeds with the same rule in HALDecorator::Policy::DSL.
## 0.3.2 / 2017-09-03
 * Allow properties without specifying a block in HALDecorator::Policy::DSL.
 * Added `allow_by_default` to HALDecorator::Policy::DSL.
## 0.3.1 / 2017-09-03
 * Classes should now extend HALDecorator instead of include it.
 * Support inheritance of Serializers.
 * Add config for setting a base uri that will get prepended to link hrefs.
 * Add method `post_serialize`
