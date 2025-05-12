# frozen_string_literal: true

require_relative 'node'
require_relative 'table_row'

module Prosemirror
  class Table < Node
    def rows
      content.select { |node| node.type == 'table_row' }
    end

    def header_row
      rows.first
    end

    def data_rows
      rows[1..] || []
    end

    # Get cell at specific position (skips header)
    def cell_at(row_index, col_index)
      return nil if row_index.negative? || col_index.negative?

      data_row = data_rows[row_index]
      return nil unless data_row

      data_row.cells[col_index]
    end

    # Create a new table
    def self.create(attrs = nil)
      table = new({ 'type' => 'table', 'content' => [] })
      table.instance_variable_set(:@attrs, attrs) if attrs
      table
    end

    # Add a header row to the table
    def add_header(header_cells)
      row = TableRow.create
      header_cells.each do |cell_content|
        row.add_cell(cell_content)
      end
      add_child(row)
      row
    end

    # Add a data row to the table
    def add_row(cell_contents = [])
      row = TableRow.create
      cell_contents.each do |cell_content|
        row.add_cell(cell_content)
      end
      add_child(row)
      row
    end

    # Add multiple rows at once
    def add_rows(rows_data)
      rows_data.each do |row_data|
        add_row(row_data)
      end
    end
  end
end
