# frozen_string_literal: true

require_relative 'node'
require_relative 'table_cell'

module Prosereflect
  class TableRow < Node
    PM_TYPE = 'table_row'

    attribute :type, :string, default: -> { send('const_get', 'PM_TYPE') }

    key_value do
      map 'type', to: :type, render_default: true
      map 'content', to: :content
      map 'attrs', to: :attrs
    end

    def initialize(opts = {})
      opts[:content] ||= []
      super
    end

    def self.create(attrs = nil)
      new(type: PM_TYPE, attrs: attrs, content: [])
    end

    def cells
      content || []
    end

    # Add a cell to the row
    def add_cell(content_text = nil, attrs: nil)
      cell = TableCell.create(attrs)

      if content_text
        paragraph = cell.add_paragraph
        paragraph.add_text(content_text)
      end

      add_child(cell)
      cell
    end

    # Override to_h to handle empty content and attributes properly
    def to_h
      result = super
      result['content'] ||= []
      if result['attrs']
        result['attrs'] = result['attrs'].is_a?(Hash) && result['attrs'][:attrs] ? result['attrs'][:attrs] : result['attrs']
        result.delete('attrs') if result['attrs'].empty?
      end
      result
    end
  end
end
