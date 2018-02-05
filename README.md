# HALPresenter
HALPresenter is a DSL for creating serializers conforming to [JSON HAL](http://stateless.co/hal_specification.html). This DSL is highly influenced by ActiveModelSerializers. My first attempted was actually to create a HAL adapter for ActiveModelSerializers. After messing around with that, I realized that it was just too messy and slow, so I decided to start over. This gem has no dependencies on other gems and will happily serialize instances of ActiveRecord, Sequel or simply POROs (most examples here will use instances of `OpenStruct` as the resource to be serialized).  
I've done some simple benchmarks against using an ActiveModelSerializers adapter and HAL and its about 5 times faster (read this with a grain of salt, I might have missed some optimizations in my adapter).  
So, generating some json from an object, whats the big deal? Well if your API is not driven by hypermedia and your payloads most of the time just looks the same, then this might be overkill. But if you do have dynamic payloads (e.g the payload attributes and links depend on the context) then this gem greatly simplifies serialization and puts all the serialization logic in one place.
This documentation might be a bit long and dull, but skim through it and check out the examples. I think you'll get the hang of it.  

## Installation
```sh
gem install hal_presenter
```
With Gemfile:

```sh
gem 'hal_presenter', '~>0.4.1'
```

And then execute:

```sh
$ bundle
```

### Name changed from HALDecorator to HALPresenter
Since serializers created using this gem actually follow the presenter pattern rather than the decorator pattern, it felt appropriate to rename the gem.
If you are upgrading from hal_decorator <= 0.3.6 then, all that is required is to install hal_presenter version >=0.4.1 and change all occurencies of `require 'hal_decorator'` to `require 'hal_presenter'. For backwards compatibility with serializers written with hal_decorator, the `HALDecorator` module will still be available when you require `hal_presenter`. Though, this will probably be removed in the future so you might want to update your serializer files. The following commands may be of great help:
```sh
grep -rl Decorator . | xargs sed -i "s/Decorator/Presenter/g"
grep -rl decorator . | xargs sed -i "s/decorator/presenter/g"
```

## Intro
Lets start with an example. Say you have your typical blog and you want to serialize post resources. Posts have some text, an author and possibly some comments. Only the author of the post may edit or delete it. A serializer could then be written as:
``` ruby
class PostSerializer
  extend HALPresenter
  model Post
  
  attribute :text
  attribute :characters do
    resource.text.size
  end
  
  link :self do
    "/posts/#{resource.id}"
  end
  
  link :author do
    "/users/#{resource.author.id}"
  end
  
  link :edit do
    "/posts/#{resource.id}/edit" if resource.author.id == options[:current_user]
  end
  
  link :delete do
    "/posts/#{resource.id}" if resource.author.id == options[:current_user]
  end
  
  embed :comments
end

```
Then instances of Post can be serialized with `HALPresenter.to_hal(post)` which will produce the following (assuming the current user is the author of the post, else the edit/delete links would not be present):

``` ruby
{   
    "characters": 25,
    "text": "some very important stuff",
    "_links": {
        "author": {
            "href": "/users/8"
        },  
        "delete": {
            "href": "/posts/5"
        },  
        "edit": {
            "href": "/posts/5/edit"
        },  
        "self": {
            "href": "/posts/5"
        }
    },
    "_embedded": {
        "comments": {
            "count": 2,
            "_links": {
                "self": {
                    "href": "/posts/5/comments"
                }
            },
            "_embedded": {
                "comments": [
                    {
                        "comment": "lorem ipsum",
                        "_links": { 
                            "self": {
                                "href": "/posts/5/comment/1"
                            }
                        }
                    },
                    {
                        "comment": "dolor sit",
                        "_links": { 
                            "self": {
                                "href": "/posts/5/comment/2"
                            }
                        }
                    }
                ]
            }
        }
    }
}

```

## Defining a Serializer
Serializers are defined by extending `HALPresenter` in the begining of the class declaration. This will add the following class methods:
- [`model(clazz)`](#model)
- [`policy(clazz)`](#policy)
- [`attribute(name, value = nil, &block)`](#attribute)
- [`link(rel, value = nil, &block)`](#link)
- [`curie(rel, value = nil, &block)`](#curie)
- [`embed(name, value = nil, presenter_class: nil, &block)`](#embed)
- [`collection`](#collection)
- [`to_hal(resource = nil, options = {})`](#to_hal)
- [`to_collection(resources = [], options = {})`](#to_collection)
- [`post_serialize(&block)`](#post_serialize)
- [`from_hal(payload, resource = nil)`](#from_hal)

### model
The `model` class method is used to register the resource Class that this serializer handles. (Theres no Rails magic that automagically maps models to serializers.)
``` ruby
class PostSerializer
  extend HALPresenter
  model Post
end
```
This make it possible to serialize Post instances using the PostSerializer.
``` ruby
post = Post.new(*args)
HALPresenter.to_hal(post)
```
Using the `model` class method is not required for serialization. The serializer can also be called directly.
``` ruby
PostSerializer.to_hal(post)
```
The serializer class may also be specified as an option, using the `:presenter` key.
``` ruby
HALPresenter.to_hal(post, {presenter: PostSerializer})
```
Even though the `model` class method is optional, it is very useful if the serializer should be selected dynamically and when the serializer is used for deserialization.

### policy
The `policy` class method is used to register a poliy class that should be used during serialization. The purpose of using a policy class is to exclude properties from being serialized depending on the context. E.g hide some attributes/link if current_user is not an admin.  
Using polices is not required, but its a nice way to structure rules about what should be shown and what actions (links) are possible to perform on a resource. The latter is usually tightly coupled with authorization in controllers. This means we can create polices with a bunch of rules and use the same policy in both serialization and in controllers. This plays very nicely with gems like [Pundit](https://github.com/elabs/pundit).
Instances of the class registered with this method needs to respond to the following methods:
- `initialize(current_user, resource, options = {})`
- `attribute?(name)`
- `link?(rel)`
- `embed?(name)`  
Additional methods will be needed for authorization in controller. Such as `create?`, `update?` etc when using Pundit.
A policy instance will be instantiated with the resource being serialized and the option `:current_user` passed to `to_hal`. For each attribute being serialized a call to `policy_instance.attribute?(name)` will be made. If that call returns `true` then the attribute will be serialized. Else it will not end up in the serialized payload. Same goes for links and embedded resources. Note that `link?(rel)` is used to discard both normal links and curies.
Using the following Policy would discard everything except a title attribute, the self link and embedded resources named foo.
``` ruby
class SomePolicy
  def initialize(current_user, resource, options = {})
  end
  
  def attribute?(name)
    name.to_s == 'title'
  end
  
  def link?(rel)
    rel == :self
  end
  
  def embed?(name)
    name.to_s == 'foo'
  end
end

```
This gem includes a DSL that simplifies creating policies. See [`HALPresenter::Policy::DSL`](#policy-dsl).

### attribute
The `attribute` class method specifies an attribute (property) to be serialized. The first argument, `name`, is required and must be a symbol of the attribute name. When `attribute` is called with only one argument, the resources being serialized are expected to respond to that argument and the returned value is what ends up in the payload.
``` ruby
class PostSerializer
  extend HALPresenter
  attribute :title
end
post = OpenStruct.new(title: "hello")
PostSerializer.to_hal(post)   # => {"title": "hello"}
```
If `attribute` is called with two arguments, then the second arguments is what ends up in the payload.
``` ruby
class PostSerializer
  extend HALPresenter
  attribute :title, "world"
end
post = OpenStruct.new(title: "hello")
PostSerializer.to_hal(post)   # => {"title": "world"}
```
When a block is passed to `attribute`, then the return value of that block is what ends up in the payload.
``` ruby
class PostSerializer
  extend HALPresenter
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
  extend HALPresenter
  link :self, '/posts/1'
end
PostSerializer.to_hal   # => {"_links": {"self": {"href": "/posts/1"}}}
```
When a block is passed to `link`, the return value of that block is what ends up as the href of the link.
``` ruby
class PostSerializer
  extend HALPresenter
  link :self do
    "/posts/#{resource.id}"
  end
end
post = OpenStruct.new(id: 5)
PostSerializer.to_hal(post)   # => {"_links": {"self": {"href": "/posts/5"}}}
```

### curie
The `curie` class method specifies a curie to be added to the _curies_ list. The first argument, `rel`, is required. `curie` must be called with either a second argument (`value`) or a block.
``` ruby
class PostSerializer
  extend HALPresenter
  curie :doc, '/api/docs/{rel}'
  link :'doc:user', '/users/5'
end
PostSerializer.to_hal   # => {"_links":{"doc:user":{"href":"/users/5"},"curies":[{"name":"doc","href":"/api/docs/{rel}","templated":true}]}}
```
When a block is passed to `curie`, the return value of that block is what ends up as the href of the curie.
``` ruby
class PostSerializer
  extend HALPresenter
  curie :doc { '/api/docs/{rel}' }
  link :'doc:user', '/users/5'
end
post = OpenStruct.new(id: 5)
PostSerializer.to_hal(post)   # => {"_links":{"doc:user":{"href":"/users/5"},"curies":[{"name":"doc","href":"/api/docs/{rel}","templated":true}]}}
```

### embed
The `embed` class method specifies a nested resource to be embedded. The first argument, `name`, is required and must be a symbol. When `embed` is called with only one argument, the resource being serialized is expected to respond to the value of that argument and the returned value is what ends up in the payload. The keyword argument `presenter_class` specifies the serializer to be used for serializing the embedded resource.
``` ruby
class UserSerializer
  extend HALPresenter
  attribute :name
end
class PostSerializer
  extend HALPresenter
  embed :author, presenter_class: UserSerializer
end
user = OpenStruct.new(name: "bengt")
post = OpenStruct.new(title: "hello", author: user)
PostSerializer.to_hal(post)   # => {"_embedded":{"author":{"name":"bengt"}}}
```
If `embed` is called with two arguments, then the second arguments is embedded.
``` ruby
class UserSerializer
  extend HALPresenter
  attribute :name
end
class PostSerializer
  extend HALPresenter
  embed :author, OpenStruct.new(name: "bengt"), presenter_class: UserSerializer
end
post = OpenStruct.new(title: "hello")
PostSerializer.to_hal(post)   # => {"_embedded":{"author":{"name":"bengt"}}}
```
When a block is passed to `embed`, then the return value of that block is embedded.
``` ruby
class UserSerializer
  extend HALPresenter
  attribute :name
end
class PostSerializer
  extend HALPresenter
  embed :author, presenter_class: UserSerializer do
    OpenStruct.new(name: "bengt")
  end
end
post = OpenStruct.new(title: "hello")
PostSerializer.to_hal(post)   # => {"_embedded":{"author":{"name":"bengt"}}}
```
 If the resource to be embedded has a registered Serializer then `presenter_class` is not needed.
 ``` ruby
class User
  def name; "bengt"; end
end
class UserSerializer
  extend HALPresenter
  model User
  attribute :name
end
class PostSerializer
  extend HALPresenter
  embed :author
end
post = OpenStruct.new(title: "hello", author: User.new)
PostSerializer.to_hal(post)   # => {"_embedded":{"author":{"name":"bengt"}}}
```

### collection
The `collection` class method is used to make a serializer capable of serializing an array of resources. Serializing collections may of course be done with separate serializer, but should we want to use the same serializer class for both then `collection` will make that work. The method takes a required keyword paramter named `:of`, which will be used as the key in the corresponding _\_embedded_ property. Each entry in first argument given to `to_collection` will then be serialized with this serializer.
``` ruby
class PostSerializer
  extend HALPresenter
  attribute :id
  attribute :title
  collection of: 'posts'
end
list = (1..2).map do |i|
  OpenStruct.new(id: i, title: "hello#{i}")
end
PostSerializer.to_collection(list)   # => {"_embedded":{"posts":[{"id":1,"title":"hello1"},{"id":2,"title":"hello2"}]}}
```
The `collection` class method takes an optional block. The purpose of this block is to be able to set attributes, links and embedded resources on the serialized collection.
``` ruby
class PostSerializer
  extend HALPresenter
  attribute :id
  attribute :title
  collection of: 'posts' do
    attribute(:number_of_posts) { resources.count }
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
  "number_of_posts": 2,
  "_links": {
    "self": {
      "href": "/posts?page=1"
    },
    "next": {
      "href": "/posts?page=2"
    }
  },
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
  }
}
```
Note: the block given to the `:number_of_posts` attribute is using the method `resources`. This is just and alias for `resource` which looks better inside collections. 

#### blocks passed to attribute, link, curie, embed and collection
Blocks passes to `attribute`, `link`, `curie` and `embed` have access to the resource being serialized throught the `resource` method. These blocks also have access to an optional `options` hash that can be passed to `to_hal`.
``` ruby
class PostSerializer
  extend HALPresenter
  attribute :title do
    "#{resource.id} -- #{resource.title} -- #{options[:extra]}"
  end
end
post = OpenStruct.new(id: 5, title: "hello")
PostSerializer.to_hal(post, {extra: 'world'})   # => {"title": "5 -- hello -- world"}
```
These blocks also have access to the scope where the block was created (e.g. the Serializer class)
``` ruby
class PostSerializer
  extend HALPresenter
  def self.bonus_text; "Common stuff"; end
  attribute :title do
    "#{bonus_text} -- #{resource.title}"
  end
end
post = OpenStruct.new(id: 5, title: "hello")
PostSerializer.to_hal(post)   # => {"title":"Common stuff -- hello"}
```
Note: this does not mean that `self` inside the block is the serializer class. The access to the serializer class methods is done by delegation.  
If the block passed to `attribute` returns `nil` then the serialized value will be `null`. If the block passed to link, curie or embed returns `nil`, then the corresponding property will not be serialized.
``` ruby
class PostSerializer
  extend HALPresenter
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


### to_hal
See examples in [`attribute`](#attribute), [`link`](#link), [`curie`](#curie) and [`embed`](#embed).
- [`collection`](#collection)

### to_collection
See examples in [`collection`](#collection)

### post_serialize
The `post_serialize` class method can used to run a hook after each serialization. This method must be called with a block taking one parameter (which will be a Hash of the serialized result). This can be convenient when dynamic properties needs to be added to the serialized payload. As an example say that you have a Form class and a FormSerializer that should be used to serialize different kinds of forms.
```ruby
  class Field
    attr_reader :name, :type, :value

    def initialize(name, params = {})
      @name = name
      @type = params[:type]
      if params.key? :value
        @value = params[:value]
        @has_value = true
      else
        @has_value = false
      end
    end

    def has_value?
      @has_value
    end
  end

  class Form
    attr_accessor :resource, :name, :title, :href, :method, :type, :self_link, :fields

    def initialize(params = {})
      @name = params[:name]
      @title = params[:title]
      @method = params[:method] || :post
      @type = params[:type] || 'application/json'
      @fields = (params[:fields] || {}).map { |name, args| Field.new(name, args) }
    end
  end
  
  class FormSerializer
    extend HALPresenter

    model Form

    attribute :method do
      (resource&.method || 'POST').to_s.upcase
    end

    attribute :name do
      resource&.name
    end

    attribute :title do
      resource&.title
    end

    attribute :href do
      resource&.href
    end

    attribute :type do
      resource&.type
    end

    link :self do
      resource&.self_link
    end

    post_serialize do |hash|
      fields = resource&.fields
      break if fields.nil? || fields.empty?
      hash[:fields] = fields.map do |field|
        { name: field.name, type: field.type }.tap do |f|
          f[:value] = field.value if field.has_value?
        end
      end
    end
  end
```
Now this setup can be used to serialize different kinds of resources with a single serializer.
```ruby
fields = {
  email: { type: "string"},
  password: { type: "string"}
}
create_form = Form.new(name: 'create-user', title: 'Create User', fields: fields.merge({username: { type: "string"}}))
create_form.href = '/users'
edit_form = Form.new(name: 'edit-user', title: 'Update User', method: :put, fields: fields)
edit_form.href = '/users/5/edit'
FormSerializer.to_hal(create_form)
FormSerializer.to_hal(edit_form)
```
This would give the following:
```ruby
{
    "fields": [
        {
            "name": "email",
            "type": "string"
        },
        {
            "name": "password",
            "type": "string"
        },
        {
            "name": "username",
            "type": "string"
        }
    ],
    "href": "/users",
    "method": "POST",
    "name": "create-user",
    "title": "Create User",
    "type": "application/json"
}

{
    "fields": [
        {
            "name": "email",
            "type": "string"
        },
        {
            "name": "password",
            "type": "string"
        }
    ],
    "href": "/users/5/edit",
    "method": "PUT",
    "name": "edit-user",
    "title": "Update User",
    "type": "application/json"
}

```

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
  extend HALPresenter
  model User
  attribute :name
  link :self, '/user'
end
class PostSerializer
  extend HALPresenter
  model Post
  attribute :title
  link :self, '/post'
  embed :author, presenter_class: UserSerializer
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
Instances are created by calling `new` on the class registered by `model` without any arguments. Then each attribute is set with *`#attribute_name=`* (e.g.
`post.title = 'hello'`)
Thus, all models used for deserialization must respond to *`attribute_name=`* for all attributes used in the serializer.  
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
  extend HALPresenter
  model User
  attribute :name
  link :self, '/user'
end
class PostSerializer
  extend HALPresenter
  model Post
  attribute :title
  link :self, '/post'
  embed :author, presenter_class: UserSerializer
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
  extend HALPresenter
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

## Inheritance
Serializers may use inheritance and should work just as expected 
```ruby
class BaseSerializer
  extend HALPresenter

  attribute :base, "will_be_overwritten"
  attribute :title
  link :self do
    resource_path(resource.id)
  end
end

class PostSerializer < BaseSerializer
  attribute :base, "child_attribute"
  
  def self.resource_path(id)
    "/posts/#{id}"
  end
end

post = OpenStruct.new(id: 5, title: 'hello')
PostSerializer.to_hal(post)   # => {"title": "hello", "base": "child_attribute", "_links": {"self": {"href": "/posts/5"}}}
```

## Config
### HALPresenter.base_href
This module method can be used to specify a base url that will get prepended to links hrefs.
```ruby
HALPresenter.base_href = 'https://localhost:3000/'

class PostSerializer
  extend HALPresenter
  link :self, '/posts/1'
end
PostSerializer.to_hal   # => {"_links": {"self": {"href": "https://localhost:3000/posts/1"}}}
```

### HALPresenter.paginate
Setting `HALPresenter.paginate = true` will add next/prev links for collections when possible. Requirements for this is:
- The resource being serialized is a paginated collection (Kaminari, will_paginate and Sequel are supported)
- The serializer being used has a collection block which declares a self link

## Policy DSL
HALPresenter includes a DSL for creating polices. By including `HALPresenter::Policy::DSL` into your policy class you get the following class methods:
- `attribute(*names, &block)`
- `link(*rels, &block)`
- `embed(*names, &block)`  
These methods all work the same way and creates one or more rules for each `name` argument (`rel` for links). If no block is given then the corresponding attribute/link/embedded resource will always be serialized. If the block evaluates to `true` then the attribute/link/embedded resource will be serialized. Otherwise it will not be serialized. The block has access to the current user, the resource that is being serialized, as well as any options passed to `to_hal` from the methods `current_user`, `resource` resp. `options`.
```ruby
class UserPolicy
  include HALPresenter::Policy::DSL

  attribute :first_name, :last_name

  attribute :email do
    # show name and email attributes if user is logged in
    !current_user.nil?
  end
  
  attribute :password do
    # Only show password if the resource belongs to current_user
    current_user && resource.user.id == current_user.id
  end
  
  link :self
  
  link :edit do
    edit?
  end
  
  embed :posts do
    !current_user.nil? && !current_user.posts.empty?
  end
  
  def edit?
    current_user && resource.user.id == current_user.id
  end
```
Notice the instance method `#edit?` which is typically used by [Pundit](https://github.com/elabs/pundit). That method is called from the block belonging to the rule for the edit link. This means that we can use the same policy class both for serialization and for authorization (and have all the rules in one place). This is great since we should only provide links to actions that are possible (authorized) and we don't want to sync this between controller code and serialization code.
