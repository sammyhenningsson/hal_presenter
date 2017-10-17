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
      unless can_serialize_collection?
        raise Error,
          "Trying to serialize a collection using #{self} which has no collection info. " \
          "Add a 'collection' spec to the serializer or use another serializer"
      end
      hash = to_collection_hash(resources, options)
      JSON.generate(hash)
    end

    protected

    def to_hash(resource, options)
      policy = policy_class&.new(options[:current_user], resource)

      {}.tap do |serialized|
        serialized.merge! serialize_attributes(resource, policy, options)
        serialized.merge! serialize_links(resource, policy, options)
        serialized.merge! serialize_embedded(resource, policy, options)

        run_post_serialize_hook!(resource, options, serialized)
      end
    end

    def to_collection_hash(resources, options)
      parameters = collection_parameters
      links = parameters.links
      curies = parameters.curies
      {}.tap do |serialized|
        serialized.merge!  _serialize_attributes(parameters.attributes, resources, nil, options)
        serialized.merge! _serialize_links(links, curies, resources, nil, options)

        serialized_resources = resources.map { |resource| to_hash(resource, options) }
        serialized[:_embedded] = { parameters.name => serialized_resources }
      end
    end

    def serialize_attributes(resource, policy, options)
      _serialize_attributes(attributes, resource, policy, options)
    end

    def serialize_links(resource, policy, options)
      _serialize_links(links, curies, resource, policy, options)
    end

    def serialize_curies(resource, policy, options)
      _serialize_curies(curies, resource, policy, options)
    end

    def serialize_embedded(resource, policy, options)
      _serialize_embedded(embedded, resource, policy, options)
    end

    def run_post_serialize_hook!(resource, options, serialized)
      hook = post_serialize_hook
      hook&.run(resource, options, serialized)
    end

    private

    def _serialize_attributes(attributes, resource, policy, options)
      attributes.each_with_object({}) do |attribute, hash|
        next if policy && !policy.attribute?(attribute.name)
        hash[attribute.name] = attribute.value(resource, options)
      end
    end

    def _serialize_links(links, curies, resource, policy, options)
      serialized = links.each_with_object({}) do |link, hash|
        next if policy && !policy.link?(link.rel)
        href = link.value(resource, options) or next
        hash[link.rel] = { href: HALDecorator.href(href) }.tap do |s|
          s[:method] = link.http_method if link.http_method
        end
      end
      curies = _serialize_curies(curies, resource, policy, options)
      serialized[:curies] = curies if curies.any?
      return {} if serialized.empty?
      { _links: serialized }
    end

    def _serialize_curies(curies, resource, policy, options)
      curies.each_with_object([]) do |curie, array|
        next if policy && !policy.link?(curie.name)
        href = curie.value(resource, options) or next
        array << {
          name: curie.name,
          href: HALDecorator.href(href),
          templated: true
        }
      end
    end

    def _serialize_embedded(embedded, object, policy, options)
      serialized = embedded.each_with_object({}) do |embed, hash|
        next if policy && !policy.embed?(embed.name)
        resource = embed.value(object, options) or next
        decorator = embed.decorator_class
        hash[embed.name] = 
          if resource.respond_to? :each
            _serialize_embedded_collection(resource, decorator, options)
          else
            decorator ||= HALDecorator.lookup_decorator(resource).first
            decorator.to_hash(resource, options)
          end
      end
      return {} if serialized.empty?
      { _embedded: serialized }
    end

    def _serialize_embedded_collection(resources, decorator, options)
      clazz = resources.first.class
      decorator ||= HALDecorator.lookup_decorator(clazz)&.first
      if decorator.nil?
        raise Serializer::Error,
          "No decorator specified to handle serializing embedded #{clazz}"
      end
      if decorator.respond_to?(:can_serialize_collection?, true) &&
          decorator.can_serialize_collection?
        decorator.to_collection_hash(resources, options)
      else
        resources.map do |resrc|
          decorator.to_hash(resrc, options)
        end
      end
    end
  end
end


