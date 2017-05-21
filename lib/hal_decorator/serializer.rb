require 'json'

module HALDecorator

  module Serializer

    class SerializerError < StandardError; end

    def to_hash(object, embed: true)
      serialized = {}
      serialized.merge! serialize_attributes(object)
      serialized.merge! serialize_links(object)
      serialized.merge! serialize_embedded(object) if embed
      serialized
    end

    protected

    def serialize_attributes(object)
      attributes.each_with_object({}) do |attribute, hash|
        hash[attribute.name] = attribute.value(object)
      end
    end

    def serialize_links(object)
      serialized = links.each_with_object({}) do |link, hash|
        serialized = { href: link.value(object) }
        serialized[:method] = link.http_method if link.http_method
        hash[link.name] = serialized
      end
      curies = serialize_curies(object)
      serialized[:curies] = curies if curies.any?
      return {} unless serialized.any?
      { _links: serialized }
    end

    def serialize_curies(object)
      curies.each_with_object([]) do |curie, array|
        array << {
          name: curie.name, 
          href: curie.value(object),
          "templated": true
        }
      end
    end

    def serialize_embedded(object)
      serialized = embedded.each_with_object({}) do |embed, hash|
        resource = embed.value(object)
        decorator = embed.decorator_class
        hash[embed.name] = 
          if resource.respond_to? :each
            decorator ||= HALDecorator.lookup_decorator(resource.first).first
            resource.map do |resrc|
              decorator.to_hash(resrc, embed: false)
            end
          else
            decorator ||= HALDecorator.lookup_decorator(resource).first
            decorator.to_hash(resource, embed: false)
          end
      end
      return {} unless serialized.any?
      { _embedded: serialized }
    end

  end
end


