require 'json'

module HALDecorator

  def self.to_hal(resource, options = {})
    raise Serializer::Error, "Resource is nil" if resource.nil?
    decorator = options.delete(:decorator)
    decorator ||= HALDecorator.lookup_decorator(resource)&.last
    raise Serializer::Error, "No decorator for #{resource}" unless decorator
    decorator.to_hal(resource, options)
  end

  def self.to_collection(resources, options = {})
    raise Serializer::Error, "resources is nil" if resources.nil?
    decorator = options.delete(:decorator)
    decorator ||= HALDecorator.lookup_decorator(resources.first)&.last
    raise Serializer::Error, "No decorator for #{resources.first}" unless decorator
    decorator.to_collection(resources, options)
  end

  module Serializer

    class Error < StandardError; end

    def to_hal(resource = nil, options = {})
      hash = to_hash(resource, options)
      JSON.generate(hash)
    end

    def to_collection(resources = [], options = {})
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

      serialized_resources = resources.map { |resource| to_hash(resource, options) }
      serialized[:_embedded] = { parameters.name => serialized_resources }
      JSON.generate(serialized)
    end

    protected

    def to_hash(resource, options)
      {}.tap do |serialized|
        serialized.merge! serialize_attributes(resource, options)
        serialized.merge! serialize_links(resource, options)
        serialized.merge! serialize_embedded(resource, options)

        run_post_serialize_hook!(resource, options, serialized)
      end
    end

    def serialize_attributes(resource, options)
      _serialize_attributes(attributes, resource, options)
    end

    def serialize_links(resource, options)
      _serialize_links(links, curies, resource, options)
    end

    def serialize_curies(resource, options)
      _serialize_curies(curies, resource, options)
    end

    def serialize_embedded(resource, options)
      _serialize_embedded(embedded, resource, options)
    end

    def run_post_serialize_hook!(resource, options, serialized)
      hook = post_serialize_hook
      hook&.run(resource, options, serialized)
    end

    private

    def _serialize_attributes(attributes, resource, options)
      attributes.each_with_object({}) do |attribute, hash|
        hash[attribute.name] = attribute.value(resource, options)
      end
    end

    def _serialize_links(links, curies, resource, options)
      serialized = links.each_with_object({}) do |link, hash|
        href = link.value(resource, options) or next
        hash[link.rel] = { href: HALDecorator.href(href) }.tap do |s|
          s[:method] = link.http_method if link.http_method
        end
      end
      curies = _serialize_curies(curies, resource, options)
      serialized[:curies] = curies if curies.any?
      return {} if serialized.empty?
      { _links: serialized }
    end

    def _serialize_curies(curies, resource, options)
      curies.each_with_object([]) do |curie, array|
        href = curie.value(resource, options) or next
        array << {
          name: curie.name,
          href: HALDecorator.href(href),
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
              decorator.to_hash(resrc, options)
            end
          else
            decorator ||= HALDecorator.lookup_decorator(resource).first
            decorator.to_hash(resource, options)
          end
      end
      return {} if serialized.empty?
      { _embedded: serialized }
    end
  end
end


