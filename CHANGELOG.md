## 1.2.0
 * Specify mediatype profile
 * Lookup presenter from single resource or collection
## 1.1.0
 * Add curie keyword argument to `::link`
 * Add curie namespace
 * Fixed bug with method_missing for inherited serializers
 * Fixed bug with `::attribute` and `::embed` when called is only one argument.
## 1.0.0
 * Move embedded curies to root resource
 * Symbolize names given to `::attribute`, `::link` and `::embed`
 * Links can now have type, deprecation, profile and title
 * Fix off-by-1 error for embed_depth in collections 
## 0.6.0
 * lookup presenter from superclass
## 0.5.0
 * Add embed_depth option for properties.
 * Drop deprecated decorator syntax.
## 0.4.3
 * Embed policies without curies also applies to rels with curies
## 0.4.2
 * Link policies without curies also applies to links with curies
 * Always serialize curies when present (policies does not need to allow curies).
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
