# frozen_string_literal: true

require_relative 'node'
require_relative 'paragraph'

module Prosereflect
  class TableCell < Node
    def paragraphs
      content.select { |node| node.type == 'paragraph' }
    end

    def text_content
      paragraphs.map(&:text_content).join("\n")
    end

    def lines
      text_content.split("\n").map(&:strip).reject(&:empty?)
    end

    # Create a new table cell
    def self.create(attrs = nil)
      cell = new({ 'type' => 'table_cell', 'content' => [] })
      cell.instance_variable_set(:@attrs, attrs) if attrs
      cell
    end

    # Add a paragraph to the cell
    def add_paragraph(text = nil)
      paragraph = Paragraph.create

      paragraph.add_text(text) if text

      add_child(paragraph)
      paragraph
    end
  end
end
