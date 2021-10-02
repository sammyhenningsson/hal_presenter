require 'json'
require 'hal_presenter/pagination'
require 'hal_presenter/curie_collection'

module HALPresenter
  module Serializer
    module ClassMethods
      def to_hal(resource, **options)
        options = options.dup
        presenter!(resource, options).to_hal(resource, options)
      end

      def to_collection(resources, **options)
        options = options.dup
        presenter!(resources, options).to_collection(resources, options)
      end

      private

      def presenter!(resources, **options)
        raise Serializer::Error, "resources is nil" if resources.nil?
        presenter = options.delete(:presenter)
        presenter ||= HALPresenter.lookup_presenter(resources)
        raise Serializer::Error, "No presenter for #{resources.first.class}" unless presenter

        presenter
      end
    end

    class Error < StandardError; end

    def self.included(base)
      base.extend(ClassMethods)
    end

    def to_hal(resource = nil, **options)
      options = options.dup
      options[:_depth] ||= 0
      hash = to_hash(resource, options)
      move_curies_to_root! hash
      return hash if options[:as_hash]

      JSON.generate(hash)
    end

    def to_collection(resources = [], **options)
      unless can_serialize_collection?
        raise Error,
          "Trying to serialize a collection using #{self} which has no collection info. " \
          "Add a 'collection' spec to the serializer or use another serializer"
      end
      options = options.dup
      options[:paginate] = HALPresenter.paginate unless options.key? :paginate
      options[:_depth] ||= 0
      hash = to_collection_hash(resources, options)
      move_curies_to_root! hash
      return hash if options[:as_hash]

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
      resources ||= []
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
        serialized_resources = resources.map { |resource| to_hash(resource, options.dup) }
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

    def move_curies_to_root!(hash)
      return if Hash(hash).empty?

      curie_collection = CurieCollection.extract_from!(hash)
      return if curie_collection.empty?

      hash[:_links] ||= {}
      hash[:_links][:curies] = curie_collection.to_a
    end


    def run_post_serialize_hook!(resource, options, serialized)
      hook = post_serialize_hook
      hook&.run(resource, options, serialized)
    end

    def _serialize_attributes(attributes, resource, policy, options)
      attributes.each_with_object({}) do |attribute, hash|
        next unless attribute.nested_depth_ok? options[:_depth]
        next if policy && !policy.attribute?(attribute.name)
        hash[attribute.name] = attribute.value(resource, options)
      end
    end

    def _serialize_links(links, curies, resource, policy, options)
      serialized = links.each_with_object({}) do |link, hash|
        rel = link.rel
        next unless link.nested_depth_ok? options[:_depth]
        next if policy && !policy.link?(rel)

        link_hash = link.to_h(resource, options)
        next if link_hash.empty?

        if hash.key? rel
          hash[rel] = [hash[rel]] unless hash[rel].is_a? Array
          hash[rel] << link_hash
        else
          hash.merge!(rel => link_hash)
        end
      end
      curies = _serialize_curies(curies, resource, options)
      serialized[:curies] = curies if curies.any?
      return {} if serialized.empty?
      { _links: serialized }
    end

    def _serialize_curies(curies, resource, options)
      curies.each_with_object([]) do |curie, array|
        next unless curie.nested_depth_ok? options[:_depth]
        hash = curie.to_h(resource, options)
        array << hash unless hash.empty?
      end
    end

    def _serialize_embedded(embedded, object, policy, options)
      serialized = embedded.each_with_object({}) do |embed, hash|
        next unless embed.nested_depth_ok? options[:_depth]
        next if policy && !policy.embed?(embed.name)
        resource = embed.value(object, options) or next
        presenter = embed.presenter_class
        embed_options = options.dup
        embed_options[:_depth] += 1
        hash[embed.name] = 
          if resource.is_a? Array
            _serialize_embedded_collection(resource, presenter, embed_options)
          else
            presenter ||= HALPresenter.lookup_presenter(resource)
            presenter.to_hash(resource, embed_options)
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
  end
end
