require 'json'
require 'hal_presenter/pagination'

module HALPresenter

  def self.to_hal(resource, options = {})
    raise Serializer::Error, "Resource is nil" if resource.nil?
    presenter = options.delete(:presenter)
    presenter ||= HALPresenter.lookup_presenter(resource)
    raise Serializer::Error, "No presenter for #{resource.class}" unless presenter
    presenter.to_hal(resource, options)
  end

  def self.to_collection(resources, options = {})
    raise Serializer::Error, "resources is nil" if resources.nil?
    presenter = options.delete(:presenter)
    presenter ||= HALPresenter.lookup_presenter(resources)
    raise Serializer::Error, "No presenter for #{resources.first.class}" unless presenter
    presenter.to_collection(resources, options)
  end

  module Serializer

    class Error < StandardError; end

    def to_hal(resource = nil, options = {})
      options[:_depth] ||= 0
      hash = to_hash(resource, options)
      move_curies_to_top! hash
      JSON.generate(hash)
    end

    def to_collection(resources = [], options = {})
      unless can_serialize_collection?
        raise Error,
          "Trying to serialize a collection using #{self} which has no collection info. " \
          "Add a 'collection' spec to the serializer or use another serializer"
      end
      options[:paginate] = HALPresenter.paginate unless options.key? :paginate
      options[:_depth] ||= 0
      hash = to_collection_hash(resources, options)
      move_curies_to_top! hash
      JSON.generate(hash)
    end

    protected

    def to_hash(resource, options)
      policy = policy_for(resource, options)
      {}.tap do |serialized|
        serialized.merge! serialize_attributes(resource, policy, options)
        serialized.merge! serialize_links(resource, policy, options)
        serialized.merge! serialize_embedded(resource, policy, options)

        run_post_serialize_hook!(resource, options, serialized)
      end
    end

    def to_collection_hash(resources, options)
      policy = policy_for(nil, options)
      properties = collection_properties
      attributes = properties.attributes
      links = properties.links
      curies = properties.curies
      embedded = properties.embedded
      {}.tap do |serialized|
        serialized.merge!  _serialize_attributes(attributes, resources, policy, options)
        serialized.merge! _serialize_links(links, curies, resources, policy, options)
        Pagination.paginate!(serialized, resources) if options[:paginate]

        # Embedded from collection block
        serialized.merge! _serialize_embedded(embedded, resources, policy, options)

        # Embedded resources
        options[:_depth] += 1
        serialized_resources = resources.map { |resource| to_hash(resource, options) }
        serialized[:_embedded] ||= {}
        serialized[:_embedded].merge!(properties.name => serialized_resources)
      end
    end

    def serialize_attributes(resource, policy, options)
      _serialize_attributes(attributes, resource, policy, options)
    end

    def serialize_links(resource, policy, options)
      _serialize_links(links, curies, resource, policy, options)
    end

    def serialize_curies(resource, policy, options)
      _serialize_curies(curies, resource, options)
    end

    def serialize_embedded(resource, policy, options)
      _serialize_embedded(embedded, resource, policy, options)
    end

    private

    def move_curies_to_top!(hash)
      curies = {}
      find_curies(hash).each do |curie|
        name = curie[:name]
        curies[name] = curie
      end

      return if curies.empty?

      hash[:_links] ||= {}
      hash[:_links][:curies] = curies.values
    end

    def find_curies(hash)
      return [] if Hash(hash).empty?

      curies = hash[:_links].delete(:curies) if hash.key? :_links
      curies ||= []

      hash.fetch(:_embedded, {}).values.each do |embedded|
        collection = embedded.is_a?(Array) ? embedded : [embedded]
        collection.each { |resrc| curies += find_curies(resrc) }
      end

      curies
    end

    def run_post_serialize_hook!(resource, options, serialized)
      hook = post_serialize_hook
      hook&.run(resource, options, serialized)
    end

    def _serialize_attributes(attributes, resource, policy, options)
      attributes.each_with_object({}) do |attribute, hash|
        next unless nested_depth_ok?(attribute, options[:_depth])
        next if policy && !policy.attribute?(attribute.name)
        hash[attribute.name] = attribute.value(resource, options)
      end
    end

    def _serialize_links(links, curies, resource, policy, options)
      serialized = links.each_with_object({}) do |link, hash|
        next unless nested_depth_ok?(link, options[:_depth])
        next if policy && !policy.link?(link.rel)
        hash.merge! link.to_h(resource, options)
      end
      curies = _serialize_curies(curies, resource, options)
      serialized[:curies] = curies if curies.any?
      return {} if serialized.empty?
      { _links: serialized }
    end

    def _serialize_curies(curies, resource, options)
      curies.each_with_object([]) do |curie, array|
        next unless nested_depth_ok?(curie, options[:_depth])
        hash = curie.to_h(resource, options)
        array << hash unless hash.empty?
      end
    end

    def _serialize_embedded(embedded, object, policy, options)
      serialized = embedded.each_with_object({}) do |embed, hash|
        next unless nested_depth_ok?(embed, options[:_depth])
        next if policy && !policy.embed?(embed.name)
        resource = embed.value(object, options) or next
        presenter = embed.presenter_class
        options[:_depth] += 1
        hash[embed.name] = 
          if resource.is_a? Array
            _serialize_embedded_collection(resource, presenter, options)
          else
            presenter ||= HALPresenter.lookup_presenter(resource)
            presenter.to_hash(resource, options)
          end
      end
      return {} if serialized.empty?
      { _embedded: serialized }
    end

    def _serialize_embedded_collection(resources, presenter, options)
      clazz = resources.first.class
      presenter ||= HALPresenter.lookup_presenter(clazz)
      if presenter.nil?
        raise Serializer::Error,
          "No presenter specified to handle serializing embedded #{clazz}"
      end
      if presenter.can_serialize_collection?
        presenter.to_collection_hash(resources, options)
      else
        resources.map do |resrc|
          presenter.to_hash(resrc, options)
        end
      end
    end

    def policy_for(resource, options)
      policy_class&.new(options[:current_user], resource, options)
    end

    def nested_depth_ok?(property, level)
      return true unless embed_depth = property.embed_depth
      level <= embed_depth
    end
  end
end
