# frozen_string_literal: true

module Prosereflect
  module Mark
    class Base < Lutaml::Model::Serializable
      PM_TYPE = "mark"

      attribute :type, :string, default: lambda {
        begin
          self.class.const_get(:PM_TYPE)
        rescue StandardError
          "mark"
        end
      }
      attribute :attrs, :hash

      key_value do
        map "type", to: :type, render_default: true
        map "attrs", to: :attrs
      end

      def self.create(attrs = nil)
        new(type: const_get(:PM_TYPE), attrs: attrs)
      rescue NameError
        new(type: "mark", attrs: attrs)
      end

      # Runtime mark-set operations (no schema exclusion or rank; see schema/mark.rb).
      def add_to_set(set)
        set.reject { |m| m.type == type } + [self]
      end

      def remove_from_set(set)
        set.reject { |m| m == self }
      end

      # Same equality remove_from_set uses, so "in the set" and "removable" can
      # never disagree.
      def is_in_set?(set)
        set.any?(self)
      end

      # The mark add_to_set would push out, or nil when it would push out
      # nothing. Lives here so the rule stays next to the one that applies it.
      def displaced_from(set)
        set.find { |m| m.type == type }
      end

      # Convert to hash for serialization
      def to_h
        result = { "type" => type }
        result["attrs"] = attrs if attrs && !attrs.empty?
        result
      end

      # Override initialize to ensure the type is set correctly
      def initialize(options = {})
        super
        # Only set the type to PM_TYPE if no type was provided in options
        self.type = begin
          options[:type] || self.class.const_get(:PM_TYPE)
        rescue StandardError
          "mark"
        end
      end
    end
  end
end
