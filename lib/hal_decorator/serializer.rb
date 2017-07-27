require 'json'

module HALDecorator

  module Serializer

    class Error < StandardError; end

    def to_hal(resource = nil, options = {})
      hash = to_hash(resource, options)
      JSON.generate(hash)
    end

    def to_hash(object, options, embed: true)
      {}.tap do |serialized|
        serialized.merge! serialize_attributes(object, options)
        serialized.merge! serialize_links(object, options)
        serialized.merge! serialize_embedded(object, options) if embed
      end
    end

    def to_collection(resources, options = {})
      parameters = collection_parameters
      if parameters.nil?
        raise Error,
          "Trying to serialize a collection using #{self} which has no collection info. " \
          "Add a 'collection' spec to the serializer or use another serializer"
      end
      links = parameters.links
      curies = parameters.curies
      serialized = _serialize_attributes(parameters.attributes, resources, options)
      serialized.merge! _serialize_links(links, curies, resources, options)

      serialized_resources = resources.map do |resource|
        to_hash(resource, embed: false)
      end
      serialized[:_embedded] = { parameters.name => serialized_resources }
      JSON.generate(serialized)
    end

    protected

    def serialize_attributes(object, options)
      _serialize_attributes(attributes, object, options)
    end

    def serialize_links(object, options)
      _serialize_links(links, curies, object, options)
    end

    def serialize_curies(object, options)
      _serialize_curies(curies, object, options)
    end

    def serialize_embedded(object, options)
      _serialize_embedded(embedded, object, options)
    end

    private

    def _serialize_attributes(attributes, object, options)
      attributes.each_with_object({}) do |attribute, hash|
        hash[attribute.name] = attribute.value(object, options)
      end
    end

    def _serialize_links(links, curies, object, options)
      serialized = links.each_with_object({}) do |link, hash|
        value = link.value(object, options) or next
        hash[link.name] = { href: value }.tap do |s|
          s[:method] = link.http_method if link.http_method
        end
      end
      curies = _serialize_curies(curies, object, options)
      serialized[:curies] = curies if curies.any?
      return {} if serialized.empty?
      { _links: serialized }
    end

    def _serialize_curies(curies, object, options)
      curies.each_with_object([]) do |curie, array|
        array << {
          name: curie.name,
          href: curie.value(object, options),
          templated: true
        }
      end
    end

    def _serialize_embedded(embedded, object, options)
      serialized = embedded.each_with_object({}) do |embed, hash|
        resource = embed.value(object, options) or next
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
      return {} if serialized.empty?
      { _embedded: serialized }
    end
  end
end


