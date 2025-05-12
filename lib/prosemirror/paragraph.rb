# frozen_string_literal: true

require_relative 'node'
require_relative 'text'
require_relative 'hard_break'

module Prosemirror
  class Paragraph < Node
    def text_nodes
      content.select { |node| node.type == 'text' }
    end

    def text_content
      result = ''
      content.each do |node|
        result += if node.type == 'text'
                    node.text_content
                  elsif node.type == 'hard_break'
                    "\n"
                  else
                    node.text_content
                  end
      end
      result
    end

    # Create a new paragraph
    def self.create(attrs = nil)
      para = new({ 'type' => 'paragraph', 'content' => [] })
      para.instance_variable_set(:@attrs, attrs) if attrs
      para
    end

    # Add text to the paragraph
    def add_text(text, marks = nil)
      return if text.nil? || text.empty?

      text_node = Text.create(text, marks)
      add_child(text_node)
      text_node
    end

    # Add a hard break to the paragraph
    def add_hard_break(marks = nil)
      hard_break = HardBreak.create(marks)
      add_child(hard_break)
      hard_break
    end
  end
end
