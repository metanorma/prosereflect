# frozen_string_literal: true

require 'lutaml/model'

module Prosereflect
  module Mark
    class Base < Lutaml::Model::Serializable
      PM_TYPE = 'mark'

      attribute :type, :string, default: lambda {
        begin
          self.class.const_get(:PM_TYPE)
        rescue StandardError
          'mark'
        end
      }
      attribute :attrs, :hash

      key_value do
        map 'type', to: :type, render_default: true
        map 'attrs', to: :attrs
      end

      def self.create(attrs = nil)
        new(type: const_get(:PM_TYPE), attrs: attrs)
      rescue NameError
        new(type: 'mark', attrs: attrs)
      end

      # Convert to hash for serialization
      def to_h
        result = { 'type' => type }
        result['attrs'] = attrs if attrs && !attrs.empty?
        result
      end

      # Override initialize to ensure the type is set correctly
      def initialize(options = {})
        super(options)
        # Only set the type to PM_TYPE if no type was provided in options
        self.type = begin
          options[:type] || self.class.const_get(:PM_TYPE)
        rescue StandardError
          'mark'
        end
      end
    end
  end
end
