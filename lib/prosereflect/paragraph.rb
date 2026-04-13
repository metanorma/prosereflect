# frozen_string_literal: true

module Prosereflect
  class Paragraph < Node
    PM_TYPE = "paragraph"

    attribute :type, :string, default: -> {
      self.class.send(:const_get, "PM_TYPE")
    }

    key_value do
      map "type", to: :type, render_default: true
      map "content", to: :content
      map "attrs", to: :attrs
      map "marks", to: :marks
    end

    def initialize(params = {})
      super
      self.content ||= []
    end

    def self.create(attrs = nil)
      new(attrs: attrs)
    end

    def text_nodes
      return [] unless content

      content.grep(Text)
    end

    def text_content
      return "" unless content

      result = ""
      content.each do |node|
        result += node.text_content
      end
      result
    end

    # Add text to the paragraph
    def add_text(text, marks = nil)
      return if text.nil? || text.empty?

      text_node = Text.create(text, marks)
      add_child(text_node)
      text_node
    end

    # Add a hard break to the paragraph
    def add_hard_break(marks = nil)
      hard_break = HardBreak.create(marks)
      add_child(hard_break)
      hard_break
    end
  end
end
