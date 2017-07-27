# HALDecorator
HALDecorator is a DSL for creating serializers conforming to JSON HAL.
## Installation
```sh
gem install
```
With Gemfile:

```sh
gem 'hal_decorator', '~>0.2.0'
```

And then execute:

```sh
$ bundle
```

## Defining a Serializer
Serializers are defined by including `HALDecorator` in the begining of the class declaration. This will add the following class methods:
- `model(clazz)`
- `attribute(name, value = nil, &block)`
- `link(rel, value = nil, &block)`
- `curie(rel, value = nil, &block)`
- `embed(name, value = nil, decorator_class: nil, &block)`
- `collection`

### model
The `model` class method is used to register the resource Class that this serializer handles.
``` ruby
class PostSerializer
  include HALDecorator
  model Post
end
```
This make it possible to serialize an instance of Post using the PostSerializer.
``` ruby
post = Post.new(*args)
HALDecorator.to_hal(post)
```
Using the `model` class method is not required for serialization. The serializer can also be called directly.
``` ruby
PostSerializer.to_hal(post)
```
Or passed as an option.
``` ruby
HALDecorator.to_hal(post, {decorator: PostSerializer})
```
Even though the `model` class method is optional, it is very useful if the serializer should be selected dynamically and when the serializer is  used for deserialization.

### attribute
The `attribute` class method specifies an attribute (property) to be serialized. The first argument, `name`, is required and must be a symbol of the attribute name. When `attribute` is called with only one argument, the resources being serialized are expected to respond to that argument and the returned value is what ends up in the payload.
``` ruby
class PostSerializer
  include HALDecorator
  attribute :title
end
post = OpenStruct.new(title: "hello")
PostSerializer.to_hal(post)   # => {"title": "hello"}
```
If `attribute` is called with two arguments, then the second arguments is what ends up in the payload.
``` ruby
class PostSerializer
  include HALDecorator
  attribute :title, "world"
end
post = OpenStruct.new(title: "hello")
PostSerializer.to_hal(post)   # => {"title": "world"}
```
When a block is passed to `attribute`, then the return value of that block is whats ends up in the payload.
``` ruby
class PostSerializer
  include HALDecorator
  attribute :title do
    resource.title.upcase
  end
end
post = OpenStruct.new(title: "hello")
PostSerializer.to_hal(post)   # => {"title": "HELLO"}
```
Notice that the resource being serialized (`post` in above example) is accessible inside the block by the `resource` method.

### link
The `link` class method specifies a link to be added to the _\_links_ property. The first argument, `rel`, is required and must be a symbol. `link` must be called with either a second argument (`value`) or a block.
``` ruby
class PostSerializer
  include HALDecorator
  link :self, '/posts/1'
end
PostSerializer.to_hal   # => {"_links": {"self": {"href": "/posts/1"}}}
```
When a block is passed to `link`, the return value of that block is whats ends up as the href of the link.
``` ruby
class PostSerializer
  include HALDecorator
  link :self do
    "/posts/#{resource.id}"
  end
end
post = OpenStruct.new(id: 5)
PostSerializer.to_hal   # => {"_links": {"self": {"href": "/posts/5"}}}
```

### curie
### embed
### collection

## Serialization
``` ruby
{
    "_embedded": {
        "comments": [
            {
                "text": "some important comments"
            },
            {
                "text": "more comments"
            }
        ]
    },
    "_links": {
        "author": {
            "href": "https://example.com/users/1"
        }
    },
    "message": "lorem ipsum..",
    "title": "hello"
}
```
## Deserialization
