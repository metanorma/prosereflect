# frozen_string_literal: true

require_relative 'node'

module Prosereflect
  # Document class represents a ProseMirror document.
  class Document < Node
    PM_TYPE = 'doc'

    def tables
      find_children('table')
    end

    def paragraphs
      find_children('paragraph')
    end

    # Add a paragraph with text to the document
    def add_paragraph(text = nil, attrs = nil)
      paragraph = Paragraph.new(attrs: attrs)

      paragraph.add_text(text) if text

      add_child(paragraph)
      paragraph
    end

    # Add a table to the document
    def add_table(attrs = nil)
      table = Table.new(attrs: attrs)
      add_child(table)
      table
    end
  end
end
