# frozen_string_literal: true

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
      PM_TYPE = 'link'
    end
  end
end
