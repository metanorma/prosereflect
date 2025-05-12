require_relative 'base'

# {
#   type: "code"
# }
module Prosereflect
  module Mark
    class Code < Base
      attribute :type, :string, default: -> { send('const_get', 'PM_TYPE') }
      PM_TYPE = 'code'
    end
  end
end
