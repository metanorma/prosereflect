require_relative 'base'

module Prosereflect
  module Attribute
    class Id < Base
      PM_TYPE = 'id'

      attribute :type, :string, default: -> { send('const_get', 'PM_TYPE') }
      attribute :id, :string

      key_value do
        map 'type', to: :type, render_default: true
        map 'id', to: :id
      end

      # Convert to hash for serialization
      def to_h
        { "id" => id }
      end
    end
  end
end
