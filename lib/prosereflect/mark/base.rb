require 'lutaml/model'

module Prosereflect
  module Mark
    class Base < Lutaml::Model::Serializable
      attribute :type, :string, default: -> { send('const_get', 'PM_TYPE') }
    end
  end
end
