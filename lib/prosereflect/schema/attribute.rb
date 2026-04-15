# frozen_string_literal: true

module Prosereflect
  class Schema
    class Attribute
      attr_reader :name, :default

      def initialize(name:, default: nil, validate: nil)
        @name = name
        @default = default
        @validate = validate
      end

      def has_default?
        !@default.nil?
      end

      def required?
        !has_default?
      end

      def validate_value(value)
        return true if @validate.nil?
        return @validate.call(value) if @validate.respond_to?(:call)

        # Handle string-based type validation like "string", "number", "string|null"
        validate_type(value, @validate.to_s)
      end

      private

      def validate_type(value, type_str)
        types = type_str.split("|")
        actual_type = get_type_name(value)

        unless types.include?(actual_type)
          raise ::Prosereflect::SchemaErrors::ValidationError,
                "Expected value of type #{types} for attribute #{@name}, got #{actual_type}"
        end
        true
      end

      def get_type_name(value)
        case value
        when nil then "null"
        when String then "string"
        when Integer, Float then "number"
        when TrueClass, FalseClass then "boolean"
        when Hash then "object"
        when Array then "object"
        else
          value.class.name.downcase
        end
      end
    end
  end
end
