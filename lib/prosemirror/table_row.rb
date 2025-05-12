# frozen_string_literal: true

require_relative 'node'
require_relative 'table_cell'

module Prosemirror
  class TableRow < Node
    def cells
      content.select { |node| node.type == 'table_cell' }
    end

    # Create a new table row
    def self.create(attrs = nil)
      row = new({ 'type' => 'table_row', 'content' => [] })
      row.instance_variable_set(:@attrs, attrs) if attrs
      row
    end

    # Add a cell to the row
    def add_cell(content_text = nil)
      cell = TableCell.create

      if content_text
        paragraph = cell.add_paragraph
        paragraph.add_text(content_text)
      end

      add_child(cell)
      cell
    end
  end
end
