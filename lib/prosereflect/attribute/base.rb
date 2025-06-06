# frozen_string_literal: true

require_relative '../attribute'

module Prosereflect
  module Attribute
    class Base < Lutaml::Model::Serializable
      PM_TYPE = 'attribute'

      attribute :type, :string, default: lambda {
        begin
          self.class.const_get(:PM_TYPE)
        rescue StandardError
          'attribute'
        end
      }
      attribute :value, :string

      key_value do
        map 'type', to: :type, render_default: true
        map 'value', to: :value
      end

      def self.create(type, value)
        new(type: type, value: value)
      end

      # Convert to hash for serialization
      def to_h
        { type => value }
      end
    end
  end
end
