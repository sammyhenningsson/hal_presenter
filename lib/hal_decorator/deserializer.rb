require 'json'

module HALDecorator

  module Deserializer

    class Error < StandardError; end

    def from_hal(payload, resource = nil)
      hash = JSON.parse(payload)
      from_hash(hash, resource)
    end

    protected

    def from_hash(hash, resource)
      if resource.nil?
        model = HALDecorator.lookup_model self
        raise Error, "No model for #{self.class}" unless model
        resource = model.new
      end
      deserialize_attributes(resource, hash)
      deserialize_embedded(resource, hash)
      resource
    end

    def deserialize_attributes(resource, hash)
      attributes.each do |attribute|
        setter_method = setter_method_name(attribute.name)
        next unless resource.respond_to? setter_method
        resource.send(setter_method, hash[attribute.name.to_s])
      end
    end

    def deserialize_embedded(resource, hash)
      embedded.each do |embed|
        setter_method = setter_method_name(embed.name) or next
        next unless resource.respond_to? setter_method
        decorator = embed.decorator_class or next

        embedded_hash = hash.dig('_embedded', embed.name.to_s)
        next unless embedded_hash&.any?

        embedded_resource = resource.send(embed.name)
        embedded_resource = 
          if embedded_hash.is_a? Array
            embedded_hash.map { |h| decorator.from_hash(h, embedded_resource) }
          else
            decorator.from_hash(embedded_hash, embedded_resource)
          end
        resource.send(setter_method, embedded_resource)
      end
    end

    private

    def setter_method_name(attr)
      "#{attr}=".to_sym
    end

  end
end



