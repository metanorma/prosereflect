# frozen_string_literal: true

require 'nokogiri'
require_relative '../document'
require_relative '../paragraph'
require_relative '../text'
require_relative '../table'
require_relative '../table_row'
require_relative '../table_cell'
require_relative '../hard_break'
require_relative '../mark/bold'
require_relative '../mark/italic'
require_relative '../mark/code'
require_relative '../mark/link'
require_relative '../attribute/href'

module Prosereflect
  module Input
    class Html
      class << self
        # Parse HTML content and return a Prosereflect::Document
        def parse(html)
          html_doc = Nokogiri::HTML(html)
          document = Document.new

          content_node = html_doc.at_css('body') || html_doc.root

          # Process all child nodes
          process_node_children(content_node, document)

          document
        end

        private

        # Process children of a node and add to parent
        def process_node_children(html_node, parent_node)
          return unless html_node && html_node.children

          html_node.children.each do |child|
            node = convert_node(child)

            if node.is_a?(Array)
              node.each { |n| parent_node.add_child(n) }
            else
              parent_node.add_child(node) if node
            end
          end
        end

        # Convert an HTML node to a ProseMirror node
        def convert_node(html_node)
          return nil if html_node.comment? || html_node.text? && html_node.text.strip.empty?

          case html_node.name
          when 'text', '#text'
            create_text_node(html_node)
          when 'p'
            create_paragraph_node(html_node)
          when 'br'
            HardBreak.new
          when 'table'
            create_table_node(html_node)
          when 'tr'
            create_table_row_node(html_node)
          when 'th', 'td'
            create_table_cell_node(html_node)
          when 'div', 'span'
            # For containers, we process their children
            handle_container_node(html_node)
          when 'strong', 'b', 'em', 'i', 'code', 'a'
            # For inline elements with text styling, we handle differently
            handle_styled_text(html_node)
          else
            # Default handling for unknown elements - try to extract content
            handle_container_node(html_node)
          end
        end

        # Create a text node from HTML text
        def create_text_node(html_node)
          Text.new(text: html_node.text)
        end

        # Create a paragraph node from HTML paragraph
        def create_paragraph_node(html_node)
          paragraph = Paragraph.new
          process_node_children(html_node, paragraph)
          paragraph
        end

        # Create a table node from HTML table
        def create_table_node(html_node)
          table = Table.new

          thead = html_node.at_css('thead')
          if thead
            thead.css('tr').each do |tr|
              process_table_row(tr, table, true)
            end
          end

          tbody = html_node.at_css('tbody') || html_node
          tbody.css('tr').each do |tr|
            process_table_row(tr, table, false)
          end

          table
        end

        # Process a table row
        def create_table_row_node(html_node)
          row = TableRow.new
          html_node.css('th, td').each do |cell|
            row.add_child(create_table_cell_node(cell))
          end
          row
        end

        # Add a row to a table
        def process_table_row(tr_node, table, is_header)
          row = create_table_row_node(tr_node)
          table.add_child(row)
        end

        # Create a table cell node from HTML cell
        def create_table_cell_node(html_node)
          cell = TableCell.new

          if contains_only_text_or_inline(html_node)
            paragraph = Paragraph.new
            process_node_children(html_node, paragraph)
            cell.add_child(paragraph)
          else
            process_node_children(html_node, cell)
          end

          cell
        end

        # Handle a container-like node (div, span, etc.)
        def handle_container_node(html_node)
          if html_node.name == 'div'
            paragraphs = html_node.css('> p')

            if paragraphs.any?
              return paragraphs.map { |p| create_paragraph_node(p) }
            end
          end

          if contains_only_text_or_inline(html_node)
            paragraph = Paragraph.new
            process_node_children(html_node, paragraph)
            return paragraph
          end

          children = []
          html_node.children.each do |child|
            node = convert_node(child)
            next unless node

            if node.is_a?(Array)
              children.concat(node)
            else
              children << node
            end
          end

          # If we have only one child, return it
          return children.first if children.size == 1

          # If we have multiple children, return the array
          return children if children.size > 1

          nil
        end

        # Handle styled text (bold, italic, etc.)
        def handle_styled_text(html_node)
          text = Text.new(text: html_node.text)

          case html_node.name
          when 'strong', 'b'
            mark = Mark::Bold.new
            mark.type = 'bold'
            text.marks = [mark]
          when 'em', 'i'
            mark = Mark::Italic.new
            mark.type = 'italic'
            text.marks = [mark]
          when 'code'
            mark = Mark::Code.new
            mark.type = 'code'
            text.marks = [mark]
          when 'a'
            mark = Mark::Link.new
            mark.type = 'link'

            if html_node['href']
              url = html_node['href']
              mark.attrs = { href: url }
            end

            text.marks = [mark]
          end

          text
        end

        # Check if a node contains only text or inline elements
        def contains_only_text_or_inline(node)
          node.children.all? do |child|
            child.text? ||
              %w[strong b em i code a br span].include?(child.name) ||
              (child.element? && contains_only_text_or_inline(child))
          end
        end
      end
    end
  end
end
