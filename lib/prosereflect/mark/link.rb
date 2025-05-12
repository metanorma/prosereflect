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
      PM_TYPE_NAME = 'link'
    end
  end
end
