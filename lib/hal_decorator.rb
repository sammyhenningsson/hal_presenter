require 'hal_decorator/attributes'
require 'hal_decorator/embedded'
require 'hal_decorator/links'
require 'hal_decorator/curies'
require 'hal_decorator/model'
require 'hal_decorator/serializer'
require 'hal_decorator/deserializer'


module HALDecorator

  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    include HALDecorator::Attributes
    include HALDecorator::Links
    include HALDecorator::Curies
    include HALDecorator::Embedded
    
    include HALDecorator::Model
    include HALDecorator::Serializer
    include HALDecorator::Deserializer

  end

  def HALDecorator.to_hal(resource, decorator: nil)
    decorator ||= HALDecorator.lookup_decorator(resource).first
    raise Serializer::SerializerError, "No decorator for #{resource}" unless decorator
    hash = decorator.to_hash(resource)
    JSON.generate(hash)
  end

  def HALDecorator.from_hal(decorator, payload)
    hash = JSON.parse(payload)
    decorator.from_hash(hash)
  end

end
