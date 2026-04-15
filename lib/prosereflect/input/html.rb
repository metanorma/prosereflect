# frozen_string_literal: true

require "nokogiri"

module Prosereflect
  module Input
    class Html
      class << self
        # Parse HTML content and return a Prosereflect::Document
        def parse(html)
          html_doc = Nokogiri::HTML(html)
          document = Document.create # Use create instead of new to initialize content array

          content_node = html_doc.at_css("body") || html_doc.root

          # Process all child nodes
          process_node_children(content_node, document)

          document
        end

        private

        # Process children of a node and add to parent
        def process_node_children(html_node, parent_node)
          return unless html_node&.children

          html_node.children.each do |child|
            node = convert_node(child)

            if node.is_a?(Array)
              node.each { |n| parent_node.add_child(n) }
            elsif node
              parent_node.add_child(node)
            end
          end
        end

        # Convert an HTML node to a ProseMirror node
        def convert_node(html_node)
          return nil if html_node.comment? || (html_node.text? && html_node.text.strip.empty?)

          case html_node.name
          when "text", "#text"
            create_text_node(html_node)
          when "p"
            create_paragraph_node(html_node)
          when /^h([1-6])$/
            create_heading_node(html_node, Regexp.last_match(1).to_i)
          when "br"
            HardBreak.new
          when "table"
            create_table_node(html_node)
          when "tr"
            create_table_row_node(html_node)
          when "th", "td"
            create_table_cell_node(html_node)
          when "ol"
            create_ordered_list_node(html_node)
          when "ul"
            create_bullet_list_node(html_node)
          when "li"
            create_list_item_node(html_node)
          when "blockquote"
            create_blockquote_node(html_node)
          when "hr"
            create_horizontal_rule_node(html_node)
          when "img"
            create_image_node(html_node)
          when "user-mention"
            create_user_node(html_node)
          when "div", "span"
            # For containers, we process their children
            handle_container_node(html_node)
          when "pre"
            create_code_block_wrapper(html_node)
          when "strong", "b", "em", "i", "code", "a", "strike", "s", "del", "sub", "sup", "u"
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

          thead = html_node.at_css("thead")
          thead&.css("tr")&.each do |tr|
            process_table_row(tr, table, true)
          end

          tbody = html_node.at_css("tbody") || html_node
          tbody.css("tr").each do |tr|
            process_table_row(tr, table, false)
          end

          table
        end

        # Process a table row
        def create_table_row_node(html_node)
          row = TableRow.new
          html_node.css("th, td").each do |cell|
            row.add_child(create_table_cell_node(cell))
          end
          row
        end

        # Add a row to a table
        def process_table_row(tr_node, table, _is_header)
          row = create_table_row_node(tr_node)
          table.add_child(row)
        end

        # Create a table cell node from HTML cell
        def create_table_cell_node(html_node)
          # Create either a TableHeader or TableCell based on the tag name
          cell = if html_node.name == "th"
                   header = TableHeader.create

                   # Handle header-specific attributes
                   header.scope = html_node["scope"] if html_node["scope"]
                   header.abbr = html_node["abbr"] if html_node["abbr"]
                   header.colspan = html_node["colspan"] if html_node["colspan"]

                   header
                 else
                   TableCell.create
                 end

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
          # For top-level divs, process children directly
          if html_node.name == "div"
            results = []
            html_node.children.each do |child|
              next if child.text? && child.text.strip.empty?

              node = convert_node(child)
              if node.is_a?(Array)
                results.concat(node)
              elsif node
                results << node
              end
            end
            return results if results.any?
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

          children
        end

        # Handle styled text (bold, italic, etc.)
        def handle_styled_text(html_node)
          # Create mark based on the current node
          mark = case html_node.name
                 when "strong", "b"
                   mark = Mark::Bold.new
                   mark.type = "bold"
                   mark
                 when "em", "i"
                   mark = Mark::Italic.new
                   mark.type = "italic"
                   mark
                 when "code"
                   mark = Mark::Code.new
                   mark.type = "code"
                   mark
                 when "a"
                   mark = Mark::Link.new
                   mark.type = "link"
                   mark.attrs = { "href" => html_node["href"] } if html_node["href"]
                   mark
                 when "strike", "s", "del"
                   mark = Mark::Strike.new
                   mark.type = "strike"
                   mark
                 when "sub"
                   mark = Mark::Subscript.new
                   mark.type = "subscript"
                   mark
                 when "sup"
                   mark = Mark::Superscript.new
                   mark.type = "superscript"
                   mark
                 when "u"
                   mark = Mark::Underline.new
                   mark.type = "underline"
                   mark
                 end

          return convert_node(html_node.children.first) unless mark

          # If the node has children that are not just text, process them
          if html_node.children.any? { |child| !child.text? }
            # Process children and add the current mark to their marks
            results = []
            html_node.children.each do |child|
              node = convert_node(child)
              next unless node

              if node.is_a?(Array)
                node.each do |n|
                  n.marks = (n.raw_marks || []) + [mark]
                  results << n
                end
              else
                node.marks = (node.raw_marks || []) + [mark]
                results << node
              end
            end
            results
          else
            # Create a text node with the mark
            text = Text.new(text: html_node.text)
            text.marks = [mark]
            text
          end
        end

        # Check if a node contains only text or inline elements
        def contains_only_text_or_inline(node)
          node.children.all? do |child|
            child.text? ||
              %w[strong b em i code a br span strike s del sub sup
                 u].include?(child.name) ||
              (child.element? && contains_only_text_or_inline(child))
          end
        end

        # Create an ordered list node from HTML ol
        def create_ordered_list_node(html_node)
          list = OrderedList.new

          # Handle start attribute
          start_val = (html_node["start"] || "1").to_i
          list.start = start_val

          # Process list items
          html_node.css("> li").each do |li|
            list.add_child(create_list_item_node(li))
          end

          list
        end

        # Create a bullet list node from HTML ul
        def create_bullet_list_node(html_node)
          list = BulletList.new
          list.bullet_style = nil

          # Handle style attribute if present
          if html_node["style"]&.include?("list-style-type")
            style = case html_node["style"]
                    when /disc/ then "disc"
                    when /circle/ then "circle"
                    when /square/ then "square"
                    end
            list.bullet_style = style
          end

          process_node_children(html_node, list)
          list
        end

        # Create a list item node from HTML li
        def create_list_item_node(html_node)
          item = ListItem.new

          # Handle text content first
          text_content = html_node.children.select do |child|
            child.text? || inline_element?(child)
          end
          if text_content.any?
            paragraph = Paragraph.new
            text_content.each do |child|
              node = convert_node(child)
              paragraph.add_child(node) if node
            end
            item.add_content(paragraph)
          end

          # Handle nested content
          html_node.children.reject do |child|
            child.text? || inline_element?(child)
          end.each do |child|
            node = convert_node(child)
            if node.is_a?(Array)
              node.each { |n| item.add_content(n) }
            elsif node
              item.add_content(node)
            end
          end

          item
        end

        # Check if a node is an inline element
        def inline_element?(node)
          return false unless node.element?

          %w[strong b em i code a br span strike s del sub sup
             u].include?(node.name)
        end

        # Create a blockquote node from HTML blockquote
        def create_blockquote_node(html_node)
          quote = Blockquote.new

          # Handle cite attribute if present
          quote.citation = html_node["cite"] if html_node["cite"]

          # Process each child separately to maintain block structure
          html_node.children.each do |child|
            next if child.text? && child.text.strip.empty?

            if child.text? || inline_element?(child)
              # Wrap loose text in paragraphs
              para = Paragraph.new
              para.add_child(convert_node(child))
              quote.add_block(para)
            else
              node = convert_node(child)
              if node.is_a?(Array)
                node.each { |n| quote.add_block(n) }
              elsif node
                quote.add_block(node)
              end
            end
          end

          quote
        end

        # Create a horizontal rule node from HTML hr
        def create_horizontal_rule_node(html_node)
          hr = HorizontalRule.new

          # Handle style attributes if present
          if html_node["style"]
            style = html_node["style"]

            # Parse border-style
            hr.style = Regexp.last_match(1) if style =~ /border-style:\s*(solid|dashed|dotted)/

            # Parse width
            hr.width = Regexp.last_match(1) if style =~ /width:\s*(\d+(?:px|%)?)/

            # Parse thickness (border-width)
            hr.thickness = Regexp.last_match(1).to_i if style =~ /border-width:\s*(\d+)px/
          end

          hr
        end

        # Create an image node from HTML img
        def create_image_node(html_node)
          # Skip images without src
          return nil unless html_node["src"]

          image = Image.new

          # Handle required src attribute
          image.src = html_node["src"]

          # Handle optional attributes
          image.alt = html_node["alt"] if html_node["alt"]
          image.title = html_node["title"] if html_node["title"]

          # Handle dimensions
          width = html_node["width"]&.to_i
          height = html_node["height"]&.to_i
          image.dimensions = [width, height] if width || height

          image
        end

        # Create a code block wrapper from HTML pre tag
        def create_code_block_wrapper(html_node)
          wrapper = CodeBlockWrapper.new
          wrapper.attrs = {
            "line_numbers" => false,
          }

          code_node = html_node.at_css("code")
          if code_node
            block = create_code_block(code_node)
            wrapper.add_child(block)
          end

          wrapper.to_h["attrs"] = {
            "line_numbers" => false,
          }
          wrapper
        end

        # Create a code block from HTML code tag
        def create_code_block(html_node)
          block = CodeBlock.new
          content = html_node.text.strip
          language = extract_language(html_node)

          block.attrs = {
            "content" => content,
            "language" => language,
            "line_numbers" => nil,
          }
          block.content = content

          block
        end

        def extract_language(html_node)
          return nil unless html_node["class"]

          return unless html_node["class"] =~ /language-(\w+)/

          Regexp.last_match(1)
        end

        # Create a heading node from HTML heading tag (h1-h6)
        def create_heading_node(html_node, level)
          heading = Heading.new
          heading.level = level
          process_node_children(html_node, heading)
          heading
        end

        # Create a user mention node from HTML user-mention element
        def create_user_node(html_node)
          # Skip user mentions without data-id
          return nil unless html_node["data-id"]

          user = User.new
          user.id = html_node["data-id"]
          user
        end

        # Parse HTML with full schema validation
        def parse_with_schema(html, schema, _rules = {})
          document = parse(html)
          validate_against_schema(document, schema)
          document
        rescue ValidationError
          # Fall back to basic parsing if validation fails
          document
        end

        # Parse HTML with custom parse rules
        def parse_with_rules(html, rules:)
          options = {
            keep_empty: rules[:keep_empty] || false,
            find_wrapping: rules[:find_wrapping],
            top_node: rules[:top_node],
            top_start: rules[:top_start],
          }.merge(rules)

          document = parse(html)
          apply_parse_rules(document, options)
        end

        # Parse a single node with context
        def parse_node(html_node, options = {})
          parent_node = options[:node]
          saved_styles = options[:saved_styles] || []
          top_node = options[:top_node] || false
          clear_null = options.fetch(:clear_null, true)

          node = convert_node(html_node)
          return nil if clear_null && node.nil?

          apply_node_options(node, parent_node, saved_styles, top_node)
        end

        # Check if whitespace should be preserved in node
        def preserve_whitespace?(node)
          return true if node.name == "pre"
          return true if node.name == "textarea"

          style = node["style"]
          return false unless style

          style.include?("white-space") && style.include?("pre")
        end

        # Determine space collapsing behavior
        def collapsed_spaces(node)
          return :preserve if preserve_whitespace?(node)
          return :collapse if node.name == "br"

          :collapse
        end

        # Normalize whitespace in text
        def normalize_whitespace(text)
          text.gsub(/\s+/, " ").strip
        end

        def validate_against_schema(document, schema)
          # Basic schema validation
          document.nodes.each do |node|
            validate_node_against_schema(node, schema)
          end
        end

        def validate_node_against_schema(node, schema)
          node_type = schema.node_type(node.type)
          return unless node_type

          # Check required content
          return unless node_type.required_content.any?

          missing = node_type.required_content - (node.content.map(&:type) & node_type.required_content)
          raise ValidationError, "Missing required content: #{missing.join(', ')}" unless missing.empty?
        end

        def apply_parse_rules(document, options)
          return document unless options[:keep_empty]

          document
        end

        def apply_node_options(node, parent_node, saved_styles, top_node)
          return node unless node.respond_to?(:marks=)

          if top_node && parent_node
            # Apply parent context marks
            node.marks = saved_styles.dup
          end
          node
        end
      end

      class ValidationError < StandardError; end
    end
  end
end
