require 'hal_decorator/attributes'
require 'hal_decorator/embedded'
require 'hal_decorator/links'
require 'hal_decorator/curies'
require 'hal_decorator/model'
require 'hal_decorator/serializer'
require 'hal_decorator/deserializer'
require 'hal_decorator/collection'


module HALDecorator

  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    include HALDecorator::Attributes
    include HALDecorator::Links
    include HALDecorator::Curies
    include HALDecorator::Embedded
    include HALDecorator::Collection
    include HALDecorator::Model
    include HALDecorator::Serializer
    include HALDecorator::Deserializer
  end

  def self.to_hal(resource, decorator: nil)
    decorator ||= HALDecorator.lookup_decorator(resource).first
    raise Serializer::SerializerError, "No decorator for #{resource}" unless decorator
    decorator.to_hal(resource)
  end

  def self.to_hal_collection(resources, decorator: nil, attributes: {}, links: {})
    decorator ||= HALDecorator.lookup_decorator(resources.first).first
    raise Serializer::SerializerError, "No decorator for #{resources.first}" unless decorator
    hash = decorator.to_collection(resources, attributes: attributes, links: links)
    JSON.generate(hash)
  end

  def self.from_hal(decorator, payload)
    decorator.from_hal(payload)
  end

end
