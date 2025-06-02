# frozen_string_literal: true

require_relative 'node'
require_relative 'paragraph'

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

    def add_paragraph(text)
      paragraph = Paragraph.new
      paragraph.add_text(text)
      add_child(paragraph)
      paragraph
    end

    def add_content(content)
      add_child(content)
    end
  end
end
