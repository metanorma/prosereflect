# frozen_string_literal: true

require_relative 'node'
require_relative 'table'
require_relative 'paragraph'
require_relative 'image'
require_relative 'bullet_list'
require_relative 'ordered_list'
require_relative 'blockquote'
require_relative 'horizontal_rule'
require_relative 'code_block_wrapper'
require_relative 'heading'
require_relative 'user'

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
        result['attrs'] = attrs_hash unless attrs_hash.empty?
      end

      # Ensure highlight_lines is an array
      if result['content']&.any?
        result['content'].each do |node|
          if node['attrs']&.key?('highlight_lines') && node['attrs']['highlight_lines'].is_a?(String)
            node['attrs']['highlight_lines'] = [node['attrs']['highlight_lines'].to_i]
          end
        end
      end

      result
    end

    def tables
      find_children(Table)
    end

    def paragraphs
      find_children(Paragraph)
    end

    # Add a heading to the document
    def add_heading(level)
      heading = Heading.new(attrs: { 'level' => level })
      add_child(heading)
      heading
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

    # Add an image to the document
    def add_image(src, alt = nil, _attrs = {})
      image = Image.new
      image.src = src
      image.alt = alt if alt
      add_child(image)
      image
    end

    # Add a user mention to the document
    def add_user(id)
      user = User.new
      user.id = id
      add_child(user)
      user
    end

    # Add a bullet list to the document
    def add_bullet_list(attrs = nil)
      list = BulletList.new(attrs: attrs)
      add_child(list)
      list
    end

    # Add an ordered list to the document
    def add_ordered_list(attrs = nil)
      list = OrderedList.new(attrs: attrs)
      add_child(list)
      list
    end

    # Add a blockquote to the document
    def add_blockquote(attrs = nil)
      quote = Blockquote.new(attrs: attrs)
      add_child(quote)
      quote
    end

    # Add a horizontal rule to the document
    def add_horizontal_rule(attrs = nil)
      hr = HorizontalRule.new(attrs: attrs)
      add_child(hr)
      hr
    end

    # Add a code block wrapper to the document
    def add_code_block_wrapper(attrs = nil)
      wrapper = CodeBlockWrapper.new(attrs: attrs)
      add_child(wrapper)
      wrapper
    end

    # Get plain text content from all nodes
    def text_content
      return '' unless content

      content.map { |node| node.respond_to?(:text_content) ? node.text_content : '' }.join("\n").strip
    end
  end
end
