require 'hal_presenter/model'
require 'hal_presenter/policy'
require 'hal_presenter/policy/dsl'
require 'hal_presenter/attributes'
require 'hal_presenter/links'
require 'hal_presenter/embedded'
require 'hal_presenter/curies'
require 'hal_presenter/serializer'
require 'hal_presenter/deserializer'
require 'hal_presenter/collection'
require 'hal_presenter/serialize_hooks'

module HALPresenter
  include HALPresenter::Attributes
  include HALPresenter::Links
  include HALPresenter::Curies
  include HALPresenter::Embedded
  include HALPresenter::Collection
  include HALPresenter::SerializeHooks
  include HALPresenter::Model
  include HALPresenter::Serializer
  include HALPresenter::Deserializer
  include HALPresenter::Policy
end

# Keeping this module for backward compatibility!
module HALDecorator
  include HALPresenter

  def self.method_missing(m, *args, &block)
    HALPresenter.send(m, *args, &block)
  end
end
