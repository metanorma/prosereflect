# frozen_string_literal: true

require_relative 'node'

module Prosereflect
  class HardBreak < Node
    def text_content
      "\n"
    end

    def text_content_with_breaks
      "\n"
    end

    # Create a new hard break
    def self.create(marks = nil)
      node = new({ 'type' => 'hard_break' })
      node.instance_variable_set(:@marks, marks) if marks
      node
    end
  end
end
