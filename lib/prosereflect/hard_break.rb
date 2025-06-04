# frozen_string_literal: true

require_relative 'node'

module Prosereflect
  class HardBreak < Node
    PM_TYPE = 'hard_break'

    attribute :type, :string, default: -> { send('const_get', 'PM_TYPE') }

    key_value do
      map 'type', to: :type, render_default: true
      map 'marks', to: :marks
    end

    def self.create(marks = nil)
      new(marks: marks)
    end

    def text_content
      "\n"
    end
  end
end
