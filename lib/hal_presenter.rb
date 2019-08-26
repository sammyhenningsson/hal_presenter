require 'hal_presenter/model'
require 'hal_presenter/policy'
require 'hal_presenter/profile'
require 'hal_presenter/policy/dsl'
require 'hal_presenter/attributes'
require 'hal_presenter/links'
require 'hal_presenter/embedded'
require 'hal_presenter/curies'
require 'hal_presenter/serializer'
require 'hal_presenter/deserializer'
require 'hal_presenter/collection'
require 'hal_presenter/serialize_hooks'
require 'hal_presenter/namespace'

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
  include HALPresenter::Profile
  include HALPresenter::Namespace
end
