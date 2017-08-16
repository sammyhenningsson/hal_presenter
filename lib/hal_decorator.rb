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
end
