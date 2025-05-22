# frozen_string_literal: true

require_relative 'base'

module Prosereflect
  module Attribute
    class Href < Base
      PM_TYPE = 'href'

      attribute :type, :string, default: -> { PM_TYPE }
      attribute :href, :string

      def initialize(options = {})
        if options.is_a?(String)
          super()
          self.value = options
        else
          super
          self.value = options[:href] if options[:href]
        end
      end
    end
  end
end
