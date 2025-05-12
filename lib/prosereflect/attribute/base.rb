require_relative '../attribute'

module Prosereflect
  module Attribute
    class Base < Lutaml::Model::Serializable
      attribute :type, :string, default: -> { send('const_get', 'PM_TYPE') }
    end
  end
end
