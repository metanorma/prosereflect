# frozen_string_literal: true

require_relative 'node'
require_relative 'table_cell'

module Prosereflect
  class TableRow < Node
    PM_TYPE = 'table_row'

    attribute :cells, TableCell, collection: true

    # Add a cell to the row
    def add_cell(content_text = nil)
      cell = TableCell.new

      if content_text
        paragraph = cell.add_paragraph
        paragraph.add_text(content_text)
      end

      add_child(cell)
      cell
    end
  end
end
