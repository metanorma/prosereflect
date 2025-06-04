# frozen_string_literal: true

require_relative 'node'
require_relative 'text'
require_relative 'paragraph'
require_relative 'table'
require_relative 'table_row'
require_relative 'table_cell'
require_relative 'table_header'
require_relative 'hard_break'
require_relative 'document'
require_relative 'heading'
require_relative 'mark/bold'
require_relative 'mark/italic'
require_relative 'mark/code'
require_relative 'mark/link'
require_relative 'ordered_list'
require_relative 'bullet_list'
require_relative 'list_item'
require_relative 'blockquote'
require_relative 'horizontal_rule'
require_relative 'image'
require_relative 'user'

module Prosereflect
  class Parser
    def self.parse(data)
      return nil unless data.is_a?(Hash)

      parse_node(data)
    end

    def self.parse_node(data)
      return nil unless data.is_a?(Hash)

      type = data['type']
      text = data['text']
      attrs = data['attrs']
      marks_data = data['marks']

      # Find the right class based on type
      node_class = case type
                   when 'doc'
                     Document
                   when 'paragraph'
                     Paragraph
                   when 'text'
                     Text
                   when 'table'
                     Table
                   when 'table_row'
                     TableRow
                   when 'table_cell'
                     TableCell
                   when 'table_header'
                     TableHeader
                   when 'hard_break'
                     HardBreak
                   when 'heading'
                     Heading
                   when 'ordered_list'
                     OrderedList
                   when 'bullet_list'
                     BulletList
                   when 'list_item'
                     ListItem
                   when 'blockquote'
                     Blockquote
                   when 'horizontal_rule'
                     HorizontalRule
                   when 'image'
                     Image
                   when 'user'
                     User
                   else
                     Node
                   end

      if type == 'text'
        node = Text.new(text: text)
      else
        node = node_class.create(attrs)

        # Process content recursively
        if data['content'].is_a?(Array)
          data['content'].each do |content_data|
            child_node = parse_node(content_data)
            node.add_child(child_node) if child_node
          end
        end
      end

      # Handle special attributes for specific node types
      case type
      when 'ordered_list'
        node.start = attrs['start'].to_i if attrs && attrs['start']
      when 'bullet_list'
        node.bullet_style = attrs['bullet_style'] if attrs && attrs['bullet_style']
      when 'blockquote'
        node.citation = attrs['cite'] if attrs && attrs['cite']
      when 'horizontal_rule'
        if attrs
          node.style = attrs['border_style'] if attrs['border_style']
          node.width = attrs['width'] if attrs['width']
          node.thickness = attrs['thickness'].to_i if attrs['thickness']
        end
      when 'image'
        if attrs
          node.src = attrs['src'] if attrs['src']
          node.alt = attrs['alt'] if attrs['alt']
          node.title = attrs['title'] if attrs['title']
          node.dimensions = [attrs['width']&.to_i, attrs['height']&.to_i]
        end
      when 'table_header'
        if attrs
          node.scope = attrs['scope'] if attrs['scope']
          node.abbr = attrs['abbr'] if attrs['abbr']
          node.colspan = attrs['colspan'] if attrs['colspan']
        end
      end

      node.marks = marks_data if marks_data && !marks_data.empty?

      node
    end

    def self.parse_document(data)
      raise ArgumentError, 'Input cannot be nil' if data.nil?
      raise ArgumentError, "Input must be a hash, got #{data.class}" unless data.is_a?(Hash)

      document = parse_node(data)

      unless document.is_a?(Document)
        # If the result isn't a Document, create one and add the node as content
        doc = Document.create
        doc.add_child(document) if document
        document = doc
      end

      document
    end
  end
end
