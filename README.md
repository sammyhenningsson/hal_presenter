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
