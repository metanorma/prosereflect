require_relative 'base'

# {
#   type: "link",
#   attrs: {
#     href: @node.attribute('href').value
#   }
# }

module Prosereflect
  module Mark
    class Link < Base
      attribute :type, :string, default: -> { send('const_get', 'PM_TYPE') }
      PM_TYPE = 'link'
    end
  end
end
