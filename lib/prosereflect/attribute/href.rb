require_relative 'base'

module Prosereflect
  module Attribute
    class Href < Base
      PM_TYPE = 'href'

      attribute :type, :string, default: -> { send('const_get', 'PM_TYPE') }
    end
  end
end
