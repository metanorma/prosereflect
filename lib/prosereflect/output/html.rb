# frozen_string_literal: true

require 'nokogiri'
require_relative '../document'

module Prosereflect
  module Output
    class Html
      class << self
        # Convert a Prosereflect::Document to HTML
        def convert(document)
          builder = Nokogiri::HTML::Builder.new do |doc|
            doc.html do
              doc.body do
                process_node(document, doc)
              end
            end
          end

          builder.to_html
        end

        private

        # Process a node and its children
        def process_node(node, builder)
          return unless node

          case node.type
          when 'doc'
            process_document(node, builder)
          when 'paragraph'
            process_paragraph(node, builder)
          when 'text'
            process_text(node, builder)
          when 'table'
            process_table(node, builder)
          when 'table_row'
            process_table_row(node, builder)
          when 'table_cell'
            process_table_cell(node, builder)
          when 'hard_break'
            builder.br
          else
            # Default handling for unknown nodes - treat as a container
            process_children(node, builder)
          end
        end

        # Process the document node
        def process_document(node, builder)
          process_children(node, builder)
        end

        # Process a paragraph node
        def process_paragraph(node, builder)
          builder.p do
            process_children(node, builder)
          end
        end

        # Process a text node, applying marks
        def process_text(node, builder)
          return unless node.text

          if node.marks && !node.marks.empty?
            apply_marks(node.text, node.marks, builder)
          else
            builder.text node.text
          end
        end

        # Apply marks to text
        def apply_marks(text, marks, builder)
          return builder.text(text) if marks.empty?

          current_mark = marks.first
          remaining_marks = marks[1..]

          mark_type = if current_mark.is_a?(Hash)
                        current_mark['type']
                      elsif current_mark.respond_to?(:type)
                        current_mark.type
                      else
                        'unknown'
                      end

          case mark_type
          when 'bold'
            builder.strong do
              apply_marks(text, remaining_marks, builder)
            end
          when 'italic'
            builder.em do
              apply_marks(text, remaining_marks, builder)
            end
          when 'code'
            builder.code do
              apply_marks(text, remaining_marks, builder)
            end
          when 'link'
            href = find_href_attribute(current_mark)
            if href
              builder.a(href: href) do
                apply_marks(text, remaining_marks, builder)
              end
            else
              apply_marks(text, remaining_marks, builder)
            end
          else
            # Unknown mark, just process inner content
            apply_marks(text, remaining_marks, builder)
          end
        end

        # Find href attribute in a link mark
        def find_href_attribute(mark)
          if mark.is_a?(Hash)
            if mark['attrs'].is_a?(Hash)
              return mark['attrs']['href']
            elsif mark['attrs'].is_a?(Array)
              href_attr = mark['attrs'].find { |a| a.is_a?(Prosereflect::Attribute::Href) || (a.is_a?(Hash) && a['type'] == 'href') }
              return href_attr['href'] if href_attr.is_a?(Hash) && href_attr['href']
              return href_attr.href if href_attr.respond_to?(:href)
            end
          elsif mark.respond_to?(:attrs)
            attrs = mark.attrs
            if attrs.is_a?(Hash)
              return attrs['href']
            elsif attrs.is_a?(Array)
              href_attr = attrs.find { |attr| attr.is_a?(Prosereflect::Attribute::Href) }
              return href_attr&.href if href_attr

              hash_attr = attrs.find { |attr| attr.is_a?(Hash) && attr['href'] }
              return hash_attr['href'] if hash_attr
            end
          end
          nil
        end

        # Process a table node
        def process_table(node, builder)
          builder.table do
            rows = node.rows || node.content
            return if rows.empty?

            builder.tbody do
              rows.each do |row|
                process_node(row, builder)
              end
            end
          end
        end

        # Process a table row
        def process_table_row(node, builder)
          builder.tr do
            process_children(node, builder)
          end
        end

        # Process a table cell
        def process_table_cell(node, builder)
          builder.td do
            if node.content&.size == 1 && node.content.first.type == 'paragraph'
              node.content.first.content&.each do |child|
                process_node(child, builder)
              end
            else
              process_children(node, builder)
            end
          end
        end

        # Process all children of a node
        def process_children(node, builder)
          return unless node.content

          node.content.each do |child|
            process_node(child, builder)
          end
        end
      end
    end
  end
end
