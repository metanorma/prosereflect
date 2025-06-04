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
            doc.div do
              process_node(document, doc)
            end
          end

          doc = Nokogiri::HTML(builder.to_html)
          html = doc.at_css('div').children.to_html

          code_blocks = {}
          html.scan(%r{<code[^>]*>(.*?)</code>}m).each_with_index do |match, i|
            code_content = match[0]
            placeholder = "CODE_BLOCK_#{i}"
            code_blocks[placeholder] = code_content
            html.sub!(code_content, placeholder)
          end

          # Remove newlines and spaces
          html = html.gsub(/\n\s*/, '')

          code_blocks.each do |placeholder, content|
            html.sub!(placeholder, content)
          end

          html
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
          when 'heading'
            process_heading(node, builder)
          when 'text'
            process_text(node, builder)
          when 'table'
            process_table(node, builder)
          when 'table_row'
            process_table_row(node, builder)
          when 'table_cell'
            process_table_cell(node, builder)
          when 'table_header'
            process_table_header(node, builder)
          when 'hard_break'
            builder.br
          when 'image'
            process_image(node, builder)
          when 'user'
            process_user(node, builder)
          when 'bullet_list'
            process_bullet_list(node, builder)
          when 'ordered_list'
            process_ordered_list(node, builder)
          when 'list_item'
            process_list_item(node, builder)
          when 'blockquote'
            process_blockquote(node, builder)
          when 'horizontal_rule'
            process_horizontal_rule(node, builder)
          when 'code_block_wrapper'
            process_code_block_wrapper(node, builder)
          when 'code_block'
            process_code_block(node, builder)
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

        # Process a heading node
        def process_heading(node, builder)
          level = node.level || 1
          builder.send("h#{level}") do
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
          when 'strike'
            builder.del do
              apply_marks(text, remaining_marks, builder)
            end
          when 'underline'
            builder.u do
              apply_marks(text, remaining_marks, builder)
            end
          when 'subscript'
            builder.sub do
              apply_marks(text, remaining_marks, builder)
            end
          when 'superscript'
            builder.sup do
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

            has_header = rows.first&.content&.any? { |cell| cell.type == 'table_header' }

            if has_header
              builder.thead do
                process_node(rows.first, builder)
              end
              rows = rows[1..]
            end

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

        # Process a table header cell
        def process_table_header(node, builder)
          attrs = {}
          attrs[:scope] = node.scope if node.scope
          attrs[:abbr] = node.abbr if node.abbr
          attrs[:colspan] = node.colspan if node.colspan

          builder.th(attrs) do
            if node.content&.size == 1 && node.content.first.type == 'paragraph'
              node.content.first.content&.each do |child|
                process_node(child, builder)
              end
            else
              process_children(node, builder)
            end
          end
        end

        # Process an image node
        def process_image(node, builder)
          attrs = {
            src: node.src,
            alt: node.alt
          }
          attrs[:title] = node.title if node.title
          attrs[:width] = node.width if node.width
          attrs[:height] = node.height if node.height

          builder.img(attrs)
        end

        # Process a user mention node
        def process_user(node, builder)
          builder << "<user-mention data-id=\"#{node.id}\"></user-mention>"
        end

        # Process a bullet list node
        def process_bullet_list(node, builder)
          builder.ul do
            node.content&.each do |child|
              if child.type == 'list_item'
                process_node(child, builder)
              else
                builder.li do
                  process_node(child, builder)
                end
              end
            end
          end
        end

        # Process an ordered list node
        def process_ordered_list(node, builder)
          attrs = {}
          attrs[:start] = node.start if node.start && node.start != 1

          builder.ol(attrs) do
            process_children(node, builder)
          end
        end

        # Process a list item node
        def process_list_item(node, builder)
          builder.li do
            process_children(node, builder)
          end
        end

        # Process a blockquote node
        def process_blockquote(node, builder)
          attrs = {}
          attrs[:cite] = node.citation if node.citation

          builder.blockquote(attrs) do
            node.blocks&.each do |block|
              process_node(block, builder)
            end
          end
        end

        # Process a horizontal rule node
        def process_horizontal_rule(node, builder)
          attrs = {}
          attrs[:style] = []
          attrs[:style] << "border-style: #{node.style}" if node.style
          attrs[:style] << "width: #{node.width}" if node.width
          attrs[:style] << "border-width: #{node.thickness}px" if node.thickness
          attrs[:style] = attrs[:style].join('; ') unless attrs[:style].empty?

          builder.hr(attrs)
        end

        # Process a code block wrapper node
        def process_code_block_wrapper(node, builder)
          attrs = {}
          if node.attrs
            attrs['data-line-numbers'] = 'true' if node.attrs['line_numbers']
            if node.attrs['highlight_lines'].is_a?(Array) && !node.attrs['highlight_lines'].empty? && node.attrs['highlight_lines'] != [0]
              attrs['data-highlight-lines'] = node.attrs['highlight_lines'].join(',')
            end
          end

          builder.pre(attrs) do
            process_children(node, builder)
          end
        end

        # Process a code block node
        def process_code_block(node, builder)
          attrs = {}
          attrs['class'] = "language-#{node.language}" if node.language

          builder.code(attrs) do
            builder.text node.content
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
