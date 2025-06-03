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
        result = { 'type' => type.to_s }
        result['attrs'] = attrs if attrs && !attrs.empty?
        result
      end
      alias to_hash to_h

      # Override initialize to ensure the type is set correctly
      def initialize(options = {})
        if options.is_a?(Hash)
          options = options.dup
          options[:type] ||= begin
            self.class.const_get(:PM_TYPE)
          rescue StandardError
            'mark'
          end
          super(options)
        else
          super()
          self.type = begin
            self.class.const_get(:PM_TYPE)
          rescue StandardError
            'mark'
          end
        end
      end

      # Override == for comparison
      def ==(other)
        return false unless other.is_a?(Base)

        type.to_s == other.type.to_s && attrs == other.attrs
      end

      # Override eql? for hash equality
      def eql?(other)
        self == other
      end

      # Override hash for hash equality
      def hash
        [type.to_s, attrs].hash
      end

      # Ensures YAML serialization outputs plain data instead of a Ruby object
      def encode_with(coder)
        coder.represent_map(nil, to_h)
      end
    end
  end
end
