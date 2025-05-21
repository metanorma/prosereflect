# frozen_string_literal: true

require_relative 'node'
require_relative 'table'
require_relative 'paragraph'

module Prosereflect
  # Document class represents a ProseMirror document.
  class Document < Node
    attribute :type, :string, default: -> { send('const_get', 'PM_TYPE') }
    PM_TYPE = 'doc'

    key_value do
      map 'type', to: :type, render_default: true
      map 'content', to: :content
      map 'attrs', to: :attrs
    end

    def self.create(attrs = nil)
      new(attrs: attrs, content: [])
    end

    # Override the to_h method to handle attribute arrays
    def to_h
      result = super

      # Handle array of attribute objects specially for serialization
      if attrs.is_a?(Array) && attrs.all? { |attr| attr.is_a?(Prosereflect::Attribute::Base) }
        attrs_hash = {}
        attrs.each do |attr|
          attrs_hash.merge!(attr.to_h)
        end
        result["attrs"] = attrs_hash unless attrs_hash.empty?
      end

      result
    end

    def tables
      find_children(Table)
    end

    def paragraphs
      find_children(Paragraph)
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
