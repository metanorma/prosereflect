# frozen_string_literal: true

require_relative 'node'

module Prosereflect
  class HardBreak < Node
    PM_TYPE = 'hard_break'

    def text_content
      "\n"
    end
  end
end
