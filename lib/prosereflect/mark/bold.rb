require_relative 'base'

# {
#   type: "bold"
# }

module Prosereflect
  module Mark
    class Bold < Base
      attribute :type, :string, default: -> { send('const_get', 'PM_TYPE') }
      PM_TYPE = 'bold'
    end
  end
end
