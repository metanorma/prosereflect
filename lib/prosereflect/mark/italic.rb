require_relative 'base'

# {
#   type: "italic"
# }

module Prosereflect
  module Mark
    class Italic < Base
      attribute :type, :string, default: -> { send('const_get', 'PM_TYPE') }
      PM_TYPE = 'italic'
    end
  end
end
