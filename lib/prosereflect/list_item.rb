# frozen_string_literal: true

require_relative 'node'
require_relative 'paragraph'
require_relative 'text'
require_relative 'hard_break'

module Prosereflect
  # ListItem class represents a list item in ProseMirror.
  class ListItem < Node
    PM_TYPE = 'list_item'

    attribute :type, :string, default: -> { send('const_get', 'PM_TYPE') }
    attribute :attrs, :hash

    key_value do
      map 'type', to: :type, render_default: true
      map 'attrs', to: :attrs
      map 'content', to: :content
    end

    def initialize(attributes = {})
      attributes[:content] ||= []
      super
    end

    def self.create(attrs = nil)
      new(attrs: attrs)
    end

    def add_paragraph(text = nil)
      paragraph = Paragraph.new
      paragraph.add_text(text) if text
      add_child(paragraph)
      paragraph
    end

    def add_content(content)
      add_child(content)
    end

    # Add text to the last paragraph, or create a new one if none exists
    def add_text(text, marks = nil)
      last_paragraph = content&.last
      last_paragraph = add_paragraph if !last_paragraph || !last_paragraph.is_a?(Paragraph)
      last_paragraph.add_text(text, marks)
      self
    end

    # Add a hard break to the last paragraph, or create a new one if none exists
    def add_hard_break(marks = nil)
      last_paragraph = content&.last
      last_paragraph = add_paragraph if !last_paragraph || !last_paragraph.is_a?(Paragraph)
      last_paragraph.add_hard_break(marks)
      self
    end

    # Get plain text content from all nodes
    def text_content
      return '' unless content

      content.map { |node| node.respond_to?(:text_content) ? node.text_content : '' }.join("\n").strip
    end
  end
end
