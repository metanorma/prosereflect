# frozen_string_literal: true

require_relative 'node'
require_relative 'paragraph'

module Prosereflect
  class TableCell < Node
    PM_TYPE = 'table_cell'

    attribute :type, :string, default: -> { send('const_get', 'PM_TYPE') }

    key_value do
      map 'type', to: :type, render_default: true
      map 'content', to: :content
      map 'attrs', to: :attrs
    end

    def initialize(attributes = {})
      super
      self.content ||= []
    end

    def self.create(attrs = nil)
      new(attrs: attrs)
    end

    def paragraphs
      return [] unless content
      content.select { |node| node.is_a?(Paragraph) }
    end

    def text_content
      paragraphs.map(&:text_content).join("\n")
    end

    def lines
      text_content.split("\n").map(&:strip).reject(&:empty?)
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
