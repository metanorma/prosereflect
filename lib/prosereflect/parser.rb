# frozen_string_literal: true

require_relative 'node'
require_relative 'text'
require_relative 'paragraph'
require_relative 'table'
require_relative 'table_row'
require_relative 'table_cell'
require_relative 'hard_break'
require_relative 'document'
require_relative 'heading'
require_relative 'mark/bold'
require_relative 'mark/italic'
require_relative 'mark/code'
require_relative 'mark/link'

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
                   when 'hard_break'
                     HardBreak
                   when 'heading'
                     Heading
                   else
                     Node
                   end

      if type == 'text'
        node = Text.new(text: text)
        node.marks = marks_data if marks_data && !marks_data.empty?
      else
        node = node_class.create(attrs)

        # Process content recursively
        if data['content'] && data['content'].is_a?(Array)
          data['content'].each do |content_data|
            child_node = parse_node(content_data)
            node.add_child(child_node) if child_node
          end
        end

        node.marks = marks_data if marks_data && !marks_data.empty?
      end

      node
    end

    def self.parse_document(data)
      raise ArgumentError, "Input cannot be nil" if data.nil?
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
