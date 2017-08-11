require 'hal_decorator/attributes'
require 'hal_decorator/embedded'
require 'hal_decorator/links'
require 'hal_decorator/curies'
require 'hal_decorator/model'
require 'hal_decorator/serializer'
require 'hal_decorator/deserializer'
require 'hal_decorator/collection'
require 'hal_decorator/serialize_hooks'

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
    include HALDecorator::SerializeHooks
    include HALDecorator::Model
    include HALDecorator::Serializer
    include HALDecorator::Deserializer
  end

  def self.to_hal(resource, options = {})
    raise Serializer::Error, "Resource is nil" if resource.nil?
    decorator = options.delete(:decorator)
    decorator ||= HALDecorator.lookup_decorator(resource)&.last
    raise Serializer::Error, "No decorator for #{resource}" unless decorator
    decorator.to_hal(resource, options)
  end

  def self.to_collection(resources, options = {})
    raise Serializer::Error, "resources is nil" if resources.nil?
    decorator = options.delete(:decorator)
    decorator ||= HALDecorator.lookup_decorator(resources.first)&.last
    raise Serializer::Error, "No decorator for #{resources.first}" unless decorator
    decorator.to_collection(resources, options)
  end

  def self.from_hal(decorator, payload, resource = nil)
    decorator.from_hal(payload, resource)
  end
end
