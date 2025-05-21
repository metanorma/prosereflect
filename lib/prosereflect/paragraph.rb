# frozen_string_literal: true

require_relative 'node'
require_relative 'text'
require_relative 'hard_break'

module Prosereflect
  class Paragraph < Node
    PM_TYPE = 'paragraph'

    attribute :type, :string, default: -> { send('const_get', 'PM_TYPE') }

    key_value do
      map 'type', to: :type, render_default: true
      map 'content', to: :content
      map 'attrs', to: :attrs
      map 'marks', to: :marks
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
      content.select { |node| node.is_a?(Text) }
    end

    def text_content
      return '' unless content

      result = ''
      content.each do |node|
        result += if node.type == 'text'
                    node.text_content
                  else
                    node.text_content
                  end
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
