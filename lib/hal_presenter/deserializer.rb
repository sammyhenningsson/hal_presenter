require 'json'

module HALPresenter
  module Deserializer
    module ClassMethods
      def from_hal(presenter, payload, resource = nil)
        presenter.from_hal(payload, resource)
      end
    end

    class Error < StandardError; end

    def self.included(base)
      base.extend ClassMethods
    end

    def from_hal(payload, resource = nil)
      return if payload.nil? || payload.empty?
      hash = JSON.parse(payload)
      from_hash(hash, resource)
    end

    protected

    def from_hash(hash, resource)
      as_collection = deserialize_as_collection?(hash)

      if resource.nil?
        model = HALPresenter.lookup_model self
        raise Error, "No model for #{self.class}" unless model
        resource = as_collection ? [] : model.new
      elsif as_collection
        resource.clear
      end

      if as_collection
        deserialize_collection(hash, resource)
      else
        deserialize_attributes(hash, resource)
        deserialize_embedded(hash, resource)
      end
      resource
    end

    def deserialize_attributes(hash, resource)
      attributes.each do |attribute|
        setter_method = setter_method_name(attribute.name)
        next unless resource.respond_to? setter_method
        resource.public_send(setter_method, hash[attribute.name.to_s])
      end
    end

    def deserialize_embedded(hash, resource)
      embedded.each do |embed|
        setter_method = setter_method_name(embed.name) or next
        next unless resource.respond_to? setter_method
        presenter = embed.presenter_class or next

        _embedded = hash.dig('_embedded', embed.name.to_s)
        next unless _embedded&.any?

        embedded_resource = resource.public_send(embed.name)
        embedded_resource = 
          if Array === _embedded
            _embedded.map { |h| presenter.from_hash(h, embedded_resource) }
          else
            presenter.from_hash(_embedded, embedded_resource)
          end
        resource.public_send(setter_method, embedded_resource)
      end
    end

    def deserialize_collection(hash, resource)
      hash['_embedded'][collection_properties.name].each do |resource_hash|
        resource << from_hash(resource_hash, nil)
      end
    end

    private

    def deserialize_as_collection?(hash)
      name = collection_properties&.name
      # return true/false (Hash#key? returns nil if not found..)
      name && hash['_embedded']&.key?(name) || false
    end

    def setter_method_name(attr)
      "#{attr}=".to_sym
    end

  end
end



