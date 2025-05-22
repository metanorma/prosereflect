# frozen_string_literal: true

require_relative 'base'

module Prosereflect
  module Attribute
    class Bold < Base
      PM_TYPE = 'bold'

      def initialize(options = {})
        super
        self.type = 'bold'
      end

      def attrs
        nil
      end
    end
  end
end
