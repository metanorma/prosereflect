# frozen_string_literal: true

require_relative 'node'

module Prosereflect
  # Document class represents a ProseMirror document.
  class Document < Node
    def initialize(data = {})
      super(data)
      @type = 'doc'
    end

    def tables
      find_children('table')
    end

    def paragraphs
      find_children('paragraph')
    end

    # Create a new empty document
    def self.create(attrs = nil)
      doc = new({ 'type' => 'doc', 'content' => [] })
      doc.instance_variable_set(:@attrs, attrs) if attrs
      doc
    end

    # Add a paragraph with text to the document
    def add_paragraph(text = nil, attrs = nil)
      paragraph = Paragraph.create(attrs)

      paragraph.add_text(text) if text

      add_child(paragraph)
      paragraph
    end

    # Add a table to the document
    def add_table(attrs = nil)
      table = Table.create(attrs)
      add_child(table)
      table
    end

    # Convert document to JSON
    def to_json(*_args)
      JSON.generate(to_h)
    end

    # Convert document to YAML
    def to_yaml
      to_h.to_yaml
    end
  end
end
