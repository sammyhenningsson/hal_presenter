module HALDecorator
  module Serializer

    def to_hash(object, embed = true)
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
        hash[link.name] = { href: link.value(object) }
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
        hash[embed.name] = 
          if resource.respond_to? :each
            resource.map { |resrc| embed.decorator_class.to_hash(resrc) }
          else
            embed.decorator_class.to_hash(resource)
          end
      end
      return {} unless serialized.any?
      { _embedded: serialized }
    end

  end
end


