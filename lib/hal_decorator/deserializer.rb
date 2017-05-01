require 'json'

module HALDecorator

  module Deserializer

    class DeserializerError < StandardError; end

    def from_hash(hash)
      model = HALDecorator.lookup_model self
      raise DeserializerError, "No model for #{self.class}" unless model
      resource = model.new
      deserialize_attributes(resource, hash)
      deserialize_embedded(resource, hash)
      resource
    end

    protected

    def deserialize_attributes(resource, hash)
      attributes.each do |attribute|
        method = "#{attribute.name}="
        next unless resource.respond_to? method
        resource.send(method, hash[attribute.name.to_s])
      end
    end

    def deserialize_embedded(resource, hash)
      embedded.each do |embed|
        method = "#{embed.name}="
        next unless resource.respond_to? method
        decorator = embed.decorator_class
        next unless decorator
        embedded_hash = hash.dig('_embedded', embed.name.to_s)
        next unless embedded_hash.any?
        if embedded_hash.is_a? Array
          embedded_resource = embedded_hash.map { |h| decorator.from_hash(h) }
        else
          embedded_resource = decorator.from_hash(embedded_hash)
        end
        resource.send(method, embedded_resource)
      end
    end

  end
end



