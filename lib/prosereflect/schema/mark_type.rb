# frozen_string_literal: true

module Prosereflect
  class Schema
    class MarkType
      attr_reader :name, :attrs, :rank, :schema, :spec
      attr_accessor :excluded

      def initialize(name:, attrs: {}, rank: 0, schema: nil, spec: nil,
inclusive: true)
        @name = name
        @attrs = attrs
        @rank = rank
        @schema = schema
        @spec = spec
        @inclusive = inclusive
        @excluded = []
      end

      def self.from_spec(name, rank, schema, spec)
        attrs = {}
        if spec.respond_to?(:attrs)
          spec_attrs = spec.attrs
          attrs = if spec_attrs.is_a?(Hash)
                    # New format: {"attr_name" => {default: value}}
                    spec_attrs.each_with_object({}) do |(attr_name, attr_spec), hash|
                      if attr_spec.respond_to?(:name)
                        hash[attr_name] =
                          Attribute.new(name: attr_spec.name,
                                        default: attr_spec.default, validate: nil)
                      else
                        # attr_spec is a Hash
                        attr_name = attr_spec[:name] || attr_spec["name"] || attr_name
                        default = attr_spec[:default] || attr_spec["default"]
                        hash[attr_name] =
                          Attribute.new(name: attr_name, default: default,
                                        validate: nil)
                      end
                    end
                  else
                    # Old format: values are attribute objects
                    spec_attrs.transform_values do |a|
                      Attribute.new(name: a.name, default: a.default, validate: nil)
                    end
                  end
        elsif spec.is_a?(Hash)
          spec_attrs = spec[:attrs] || spec["attrs"] || {}
          attrs = spec_attrs.transform_values do |v|
            Attribute.new(name: v[:name] || v["name"],
                          default: v[:default] || v["default"])
          end
        end

        new(
          name: name,
          attrs: attrs,
          rank: rank,
          schema: schema,
          spec: spec,
          inclusive: if spec.respond_to?(:inclusive)
                       spec.inclusive
                     elsif spec.key?(:inclusive)
                       spec[:inclusive]
                     elsif spec.key?("inclusive")
                       spec["inclusive"]
                     else
                       true
                     end,
        )
      end

      def create(attrs = nil)
        return instance if attrs.nil? && @instance

        computed_attrs = compute_attrs(attrs)
        Mark.new(type: self, attrs: computed_attrs)
      end

      def remove_from_set(mark_set)
        mark_set.reject { |m| m.type == self }
      end

      def is_in_set?(mark_set)
        mark_set.any? { |m| m.type == self }
      end

      def check_attrs(attrs)
        attrs ||= {}
        attrs.each do |attr_name, value|
          unless @attrs.key?(attr_name)
            raise Prosereflect::SchemaErrors::ValidationError,
                  "Unsupported attribute #{attr_name} for mark #{@name}"
          end

          attr_def = @attrs[attr_name]
          attr_def&.validate_value(value)
        end
      end

      def excludes?(other_mark_type)
        @excluded.include?(other_mark_type)
      end

      def inclusive?
        @inclusive
      end

      def instance
        @instance ||= create(nil)
      end

      private

      def compute_attrs(attrs)
        built = {}
        @attrs.each do |name, attr_def|
          if attrs&.key?(name)
            built[name] = attrs[name]
          elsif attr_def.has_default?
            built[name] = attr_def.default
          else
            raise Prosereflect::SchemaErrors::ValidationError,
                  "No value supplied for required attribute #{name} on mark #{@name}"
          end
        end
        built
      end
    end
  end
end
