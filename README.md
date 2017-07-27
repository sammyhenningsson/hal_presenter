# HALDecorator
HALDecorator is a DSL for creating serializers conforming to [JSON HAL](http://stateless.co/hal_specification.html).
## Installation
```sh
gem install
```
With Gemfile:

```sh
gem 'hal_decorator', '~>0.2.1'
```

And then execute:

```sh
$ bundle
```

## Defining a Serializer
Serializers are defined by including `HALDecorator` in the begining of the class declaration. This will add the following class methods:
- [`model(clazz)`](#model)
- [`attribute(name, value = nil, &block)`](#attribute)
- [`link(rel, value = nil, &block)`](#link)
- [`curie(rel, value = nil, &block)`](#curie)
- [`embed(name, value = nil, decorator_class: nil, &block)`](#embed)
- [`collection`](#collection)
- `to_hal(resource = nil, options = {})`
- `to_collection(resources = [], options = {})`
- [`from_hal(payload, resource = nil)`](#from_hal)

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
The serializer class may also be specified as an option, using the `:decorator` key.
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
Notice that the resource being serialized (`post` in the above example) is accessible inside the block by the `resource` method.

### link
The `link` class method specifies a link to be added to the _\_links_ property. The first argument, `rel`, is required. `link` must be called with either a second argument (`value`) or a block.
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
The `curie` class method specifies a curie to be added to the _curies_ list. The first argument, `rel`, is required. `curie` must be called with either a second argument (`value`) or a block.
``` ruby
class PostSerializer
  include HALDecorator
  curie :doc, '/api/docs/{rel}'
  link :'doc:user', '/users/5'
end
PostSerializer.to_hal   # => {"_links":{"doc:user":{"href":"/users/5"},"curies":[{"name":"doc","href":"/api/docs/{rel}","templated":true}]}}
```
When a block is passed to `curie`, the return value of that block is whats ends up as the href of the curie.
``` ruby
class PostSerializer
  include HALDecorator
  curie :doc { '/api/docs/{rel}' }
  link :'doc:user', '/users/5'
end
post = OpenStruct.new(id: 5)
PostSerializer.to_hal   # => {"_links":{"doc:user":{"href":"/users/5"},"curies":[{"name":"doc","href":"/api/docs/{rel}","templated":true}]}}
```

### embed
The `embed` class method specifies a nested resource to be embedded. The first argument, `name`, is required and must be a symbol. When `embed` is called with only one argument, the resource being serialized is expected to respond to the value of that argument and the returned value is what ends up in the payload. The keyword argument `decorator_class` specifies the serializer to be used for serializing the embedded resource.
``` ruby
class UserSerializer
  include HALDecorator
  attribute :name
end
class PostSerializer
  include HALDecorator
  embed :author, decorator_class: UserSerializer
end
user = OpenStruct.new(name: "bengt")
post = OpenStruct.new(title: "hello", author: user)
PostSerializer.to_hal(post)   # => {"_embedded":{"author":{"name":"bengt"}}}
```
If `embed` is called with two arguments, then the second arguments is embedded.
``` ruby
class UserSerializer
  include HALDecorator
  attribute :name
end
class PostSerializer
  include HALDecorator
  embed :author, OpenStruct.new(name: "bengt"), decorator_class: UserSerializer
end
post = OpenStruct.new(title: "hello")
PostSerializer.to_hal(post)   # => {"_embedded":{"author":{"name":"bengt"}}}
```
When a block is passed to `embed`, then the return value of that block is embedded.
``` ruby
class UserSerializer
  include HALDecorator
  attribute :name
end
class PostSerializer
  include HALDecorator
  embed :author, decorator_class: UserSerializer do
    OpenStruct.new(name: "bengt")
  end
end
post = OpenStruct.new(title: "hello")
PostSerializer.to_hal(post)   # => {"_embedded":{"author":{"name":"bengt"}}}
```
 If the resource to be embedded has a registered Serializer then `decorator_class` is not needed.
 ``` ruby
class User
  def name; "bengt"; end
end
class UserSerializer
  include HALDecorator
  model User
  attribute :name
end
class PostSerializer
  include HALDecorator
  embed :author
end
post = OpenStruct.new(title: "hello", author: User.new)
PostSerializer.to_hal(post)   # => {"_embedded":{"author":{"name":"bengt"}}}
```

#### blocks passed to attribute, link, curie and embed
Blocks passes to `attribute`, `link`, `curie` and `embed` have access to the resource being serialized througth the `resource` method. These blocks also have access to an optional options hash that can be passed to `to_hal`.
``` ruby
class UserSerializer
  include HALDecorator
  model User
  attribute :name
end
class PostSerializer
  include HALDecorator
  attribute :title do
    "#{resource.id} -- #{resource.title} -- #{options[:extra]}"
  end
end
post = OpenStruct.new(id: 5, title: "hello")
PostSerializer.to_hal(post, {extra: 'world'})   # => {"title": "5 -- hello -- world"}
```
These blocks also have acces to the scope where the block was created (e.g. the Serializer class)
``` ruby
class PostSerializer
  include HALDecorator
  def self.bonus_text; "Common stuff"; end
  attribute :title do
    "#{bonus_text} -- #{resource.title}"
  end
end
post = OpenStruct.new(id: 5, title: "hello")
PostSerializer.to_hal(post)   # => {"title":"Common stuff -- hello"}
```
Note: this does not mean that `self` inside the block is the serializer class. The access to the serializer class methods is done by delegation.  
If the block passed to `attribute` returns nil then the serialized value will be `null`. If the block passed to link, curie or embed returns nil, then the corresponding property will not be serialized.
``` ruby
class PostSerializer
  include HALDecorator
  attribute :title
  attribute :foo { nil }
  link :self { "/posts/#{resource.id}" }
  link :edit do
    "/posts/#{resource.id}" if resource.author_id == options[:current_user].id
  end
end
user = OpenStruct.new(id: 5)
post = OpenStruct.new(id: 1, title: "hello", author_id: 2)
PostSerializer.to_hal(post, {current_user: user})   # => {"title":"hello","foo":null,"_links":{"self":{"href":"/posts/1"}}}

user = OpenStruct.new(id: 2)
PostSerializer.to_hal(post, {current_user: user})   # => "{"title":"hello","foo":null,"_links":{"self":{"href":"/posts/1"},"edit":{"href":"/posts/1"}}}"
```

### collection
The `collection` class method is used to make a serializer capable of serializing an array of resources. Serializing collections may of course be done with separate serializer, but should we want to use the same serializer class for both then `collection` will make that work. The method takes a required keyword paramter named `:of`, which will be used as the key in corresponding _\_embedded_ property. Each entry in first argument given to `to_collection` will then be serialized with this serializer.
``` ruby
class PostSerializer
  include HALDecorator
  attribute :id
  attribute :title
  collection of: 'posts'
end
list = (1..2).map do |i|
  OpenStruct.new(id: i, title: "hello#{i}")
end
PostSerializer.to_collection(list)   # => {"_embedded":{"posts":[{"id":1,"title":"hello1"},{"id":2,"title":"hello2"}]}}
```
The `collection` class method takes an optional block. The purpose of this block is to be able to set properties and links on the serialized collection. Note this block does not have the same access as blocks passed to `attribute`, `link`, `curie` and `embed`.
``` ruby
class PostSerializer
  include HALDecorator
  attribute :id
  attribute :title
  collection of: 'posts' do
    attribute :number_of_posts { resources.count }
    link :self do
      format "/posts%s", (options[:page] && "?page=#{options[:page]}")
    end
    link :next do
      "/posts?page=#{options[:next]}" if options[:next]
    end
  end
end
list = (1..2).map do |i|
  OpenStruct.new(id: i, title: "hello#{i}")
end
PostSerializer.to_collection(list, {page: 1, next: 2})   # => {"number_of_posts":2,"_links":{"self":{"href":"/posts?page=1"},"next":{"href":"/posts?page=2"}},"_embedded":{"posts":[{"id":1,"title":"hello1"},{"id":2,"title":"hello2"}]}}"
```
The response above with some newlines.
```sh
{
    "_embedded": {
        "posts": [
            {
                "id": 1,
                "title": "hello1"
            },
            {
                "id": 2,
                "title": "hello2"
            }
        ]
    },
    "_links": {
        "next": {
            "href": "/posts?page=2"
        },
        "self": {
            "href": "/posts?page=1"
        }
    },
    "count": 2
}
```
Note: the block given to the `:number_of_posts` attribute is using the method `resources`. This is just and alias for `resource` which looks better inside collections. 

### from_hal
The class method `from_hal` is used to deserialize a payload into a model instance. If there are links in the payload they will be discarded. Fields in the payload that
does not have a corresponding attribute or embed in the serializer will be ignored.

```ruby
class User
  attr_accessor :name
end
class Post
  attr_accessor :title, :author
end
class UserSerializer
  include HALDecorator
  model User
  attribute :name
  link :self, '/user'
end
class PostSerializer
  include HALDecorator
  model Post
  attribute :title
  link :self, '/post'
  embed :author, decorator_class: UserSerializer
end
user = User.new.tap { |user| user.name = "bengt" }
post = Post.new.tap do |post|
  post.title= "hello"
  post.author = user
end
payload = PostSerializer.to_hal(post)   # => {"title":"hello","_links":{"self":{"href":"/post"}},"_embedded":{"author":{"name":"bengt","_links":{"self":{"href":"/user"}}}}}"

post = PostSerializer.from_hal(payload)
post.title                               # => "hello"
post.author.name                         # => "bengt"

```
Instances are created by calling `new` on the class registered by `model` without any arguments. Then each attribute is set with `#_attribute\_name_=` (e.g.
`post.title = 'hello'`)
Thus, all models used for deserialization must respond to `_attribute\_name_=` for all attributes used in the serializer.  
If the model can't be created without arguments (or if the instance already exit), then the instance can be passed to `from_hal`.
```ruby
class User
  attr_accessor :name
  def initialize(name)
    @name = name
  end
end
class Post
  attr_accessor :title, :author
  def initialize(title, author)
    @title = title
    @author = author
  end
end
class UserSerializer
  include HALDecorator
  model User
  attribute :name
  link :self, '/user'
end
class PostSerializer
  include HALDecorator
  model Post
  attribute :title
  link :self, '/post'
  embed :author, decorator_class: UserSerializer
end
payload = JSON.generate(
  {
    "title": "hello",
    "_links": {
      "self": {
        "href": "/post"
      }
    },
    "_embedded": {
      "author": {
        "_links": {
          "self": {
            "href": "/user"
          }
        },
        "name": "bengt"
      }
    }
  }
)

user = User.new('will_be_overwritten')
post = Post.new('will_be_overwritten', user)

post = PostSerializer.from_hal(payload, post)
post.title                               # => "hello"
post.author.name                         # => "bengt"
```
Collections can be deserialized into an array as long as the serialiazer has a collection. In this case the model instance cannot be passed as an argument
so it must be possbile to create new instances with _ModelName_.new (whithout any arguments).
```ruby
class User
  attr_accessor :name
end
class UserSerializer
  include HALDecorator
  model User
  attribute :name
  link :self, '/user'
  collection of: 'users'
end

users =  (1..5).map do |i|
  {
    name: "user#{i}",
    foo: "ignored"
  }
end
payload = JSON.generate(
  {
    _embedded: {
      users: users
    }
  }
)

users = UserSerializer.from_hal(payload)
users.class                              # => Array
users.first.class                        # => User
users.map(&:name)                        # => ["user1", "user2", "user3", "user4", "user5"]                         
```

