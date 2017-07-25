require 'json'

module HALDecorator

  module Serializer

    class SerializerError < StandardError; end

    def to_hal(resource, options = {})
      hash = to_hash(resource, options)
      JSON.generate(hash)
    end

    def to_hash(object, options, embed: true)
      serialized = {}
      serialized.merge! serialize_attributes(object, options)
      serialized.merge! serialize_links(object, options)
      serialized.merge! serialize_embedded(object, options) if embed
      serialized
    end

    def to_collection(resources, options)
      attributes = options.delete(:attributes) { Hash.new }
      links      = options.delete(:links) { Hash.new }

      serialized = {}
      attributes.each do |key,value|
        serialized[key] = value
      end

      serialized_resources = resources.map do |resource|
        to_hash(resource, embed: false)
      end
      if collection_name
        serialized_resources = {collection_name => serialized_resources}
      end
      serialized[:_embedded] = serialized_resources
      serialized
    end

    protected

    def serialize_attributes(object, options)
      attributes.each_with_object({}) do |attribute, hash|
        hash[attribute.name] = attribute.value(object, options)
      end
    end

    def serialize_links(object, options)
      serialized = links.each_with_object({}) do |link, hash|
        serialized = { href: link.value(object, options) }
        serialized[:method] = link.http_method if link.http_method
        hash[link.name] = serialized
      end
      curies = serialize_curies(object, options)
      serialized[:curies] = curies if curies.any?
      return {} unless serialized.any?
      { _links: serialized }
    end

    def serialize_curies(object, options)
      curies.each_with_object([]) do |curie, array|
        array << {
          name: curie.name, 
          href: curie.value(object, options),
          "templated": true
        }
      end
    end

    def serialize_embedded(object, options)
      serialized = embedded.each_with_object({}) do |embed, hash|
        resource = embed.value(object, options)
        decorator = embed.decorator_class
        hash[embed.name] = 
          if resource.respond_to? :each
            decorator ||= HALDecorator.lookup_decorator(resource.first).first
            resource.map do |resrc|
              decorator.to_hash(resrc, options, embed: false)
            end
          else
            decorator ||= HALDecorator.lookup_decorator(resource).first
            decorator.to_hash(resource, options, embed: false)
          end
      end
      return {} unless serialized.any?
      { _embedded: serialized }
    end

  end
end


