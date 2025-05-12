# frozen_string_literal: true

require_relative 'node'
require_relative 'text'
require_relative 'hard_break'

module Prosereflect
  class Paragraph < Node
    PM_TYPE = 'paragraph'

    def text_nodes
      content.select { |node| node.type == 'text' }
    end

    def text_content
      result = ''
      content.each do |node|
        result += if node.type == 'text'
                    node.text_content
                  else
                    node.text_content
                  end
      end
      result
    end

    # Add text to the paragraph
    def add_text(text, marks = nil)
      return if text.nil? || text.empty?

      text_node = Text.new(text: text, marks: marks)
      add_child(text_node)
      text_node
    end

    # Add a hard break to the paragraph
    def add_hard_break(marks = nil)
      hard_break = HardBreak.new(marks: marks)
      add_child(hard_break)
      hard_break
    end
  end
end
