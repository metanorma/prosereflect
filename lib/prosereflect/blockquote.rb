# frozen_string_literal: true

require_relative 'node'
require_relative 'paragraph'

module Prosereflect
  # It can contain other block-level content like paragraphs, lists, etc.
  class Blockquote < Node
    PM_TYPE = 'blockquote'

    attribute :type, :string, default: -> { send('const_get', 'PM_TYPE') }
    attribute :citation, :string
    attribute :attrs, :hash

    key_value do
      map 'type', to: :type, render_default: true
      map 'content', to: :content
      map 'attrs', to: :attrs
    end

    def initialize(attributes = {})
      attributes[:content] ||= []
      super
    end

    def self.create(attrs = nil)
      new(attrs: attrs, content: [])
    end

    # Get all content blocks within the blockquote
    def blocks
      return [] unless content

      content
    end

    # Add a content block to the blockquote
    def add_block(content)
      add_child(content)
    end

    # Add multiple content blocks at once
    def add_blocks(blocks_content)
      blocks_content.each do |block_content|
        add_block(block_content)
      end
    end

    # Get block at specific position
    def block_at(index)
      return nil if index.negative?

      blocks[index]
    end

    # Update citation/source for the blockquote
    def citation=(source)
      self.attrs ||= {}
      attrs['citation'] = source
    end

    # Get citation/source of the blockquote
    def citation
      attrs&.[]('citation')
    end

    # Check if blockquote has a citation
    def citation?
      !citation.nil? && !citation.empty?
    end

    # Remove citation
    def remove_citation
      self.attrs ||= {}
      attrs.delete('citation')
    end

    def add_paragraph(text)
      paragraph = Paragraph.new
      paragraph.add_text(text)
      add_child(paragraph)
      paragraph
    end
  end
end
