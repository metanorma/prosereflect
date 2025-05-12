require_relative 'base'

module Prosereflect
  module Attribute
    class Id < Base
      PM_TYPE = 'id'

      attribute :type, :string, default: -> { send('const_get', 'PM_TYPE') }
      attribute :id, :string
    end
  end
end
