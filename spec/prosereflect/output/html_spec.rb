# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Prosereflect::Output::Html do
  describe '.convert' do
    it 'converts a simple document to HTML' do
      document = Prosereflect::Document.new
      document.add_paragraph('This is a test paragraph.')

      html = described_class.convert(document)

      expect(html).to include('<p>This is a test paragraph.</p>')
    end

    it 'converts styled text to HTML' do
      document = Prosereflect::Document.new
      paragraph = document.add_paragraph

      # Add text with different styles
      paragraph.add_text('This is ')
      paragraph.add_text('bold', [Prosereflect::Mark::Bold.new])
      paragraph.add_text(' and ')
      paragraph.add_text('italic', [Prosereflect::Mark::Italic.new])
      paragraph.add_text(' text.')

      html = described_class.convert(document)

      # Test only that the expected tags appear in the result, not the exact structure
      expect(html).to include('<strong>bold</strong>')
      expect(html).to include('<em>italic</em>')
      expect(html).to include('This is')
      expect(html).to include('and')
      expect(html).to include('text.')
    end

    it 'converts tables to HTML' do
      document = Prosereflect::Document.new
      table = document.add_table

      # Add header row
      table.add_header(['Header 1', 'Header 2'])

      # Add data rows
      table.add_row(['Row 1, Cell 1', 'Row 1, Cell 2'])
      table.add_row(['Row 2, Cell 1', 'Row 2, Cell 2'])

      html = described_class.convert(document)

      expect(html).to include('<table>')
      expect(html).to include('<tbody>')
      expect(html).to include('<tr>')
      expect(html).to include('<thead>')
      expect(html).to include('<th')
      expect(html).to include('Header 1')
      expect(html).to include('Row 1, Cell 1')
    end

    it 'converts links to HTML' do
      document = Prosereflect::Document.new
      paragraph = document.add_paragraph

      # Create a link mark with href attribute
      link_mark = Prosereflect::Mark::Link.new
      href_attr = Prosereflect::Attribute::Href.new(href: 'https://example.com')
      link_mark.attrs = [href_attr]

      paragraph.add_text('Visit Example', [link_mark])

      html = described_class.convert(document)

      # Test for link components rather than exact HTML structure
      expect(html).to include('href="https://example.com"')
      expect(html).to include('Visit Example')
      expect(html).to include('<a')
      expect(html).to include('</a>')
    end

    it 'handles line breaks' do
      document = Prosereflect::Document.new
      paragraph = document.add_paragraph('Line 1')
      paragraph.add_hard_break
      paragraph.add_text('Line 2')

      html = described_class.convert(document)

      expect(html).to include('Line 1<br>Line 2')
    end

    it 'converts images to HTML' do
      document = Prosereflect::Document.new
      image = document.add_image('example.jpg', 'Example image')
      image.title = 'Image tooltip'
      image.width = 800
      image.height = 600

      html = described_class.convert(document)

      expect(html).to include('<img')
      expect(html).to match(/src="example\.jpg"/)
      expect(html).to match(/alt="Example image"/)
      expect(html).to match(/title="Image tooltip"/)
      expect(html).to match(/width="800"/)
      expect(html).to match(/height="600"/)
    end

    it 'converts bullet lists to HTML' do
      document = Prosereflect::Document.new
      list = document.add_bullet_list
      list.bullet_style = 'square'

      list.add_item('First item')
      list.add_item('Second item')

      html = described_class.convert(document)

      expect(html).to include('<ul')
      expect(html).to include('style="list-style-type: square"')
      expect(html).to include('<li><p>First item</p></li>')
      expect(html).to include('<li><p>Second item</p></li>')
    end

    it 'converts ordered lists to HTML' do
      document = Prosereflect::Document.new
      list = document.add_ordered_list
      list.start = 3

      list.add_item('Third item')
      list.add_item('Fourth item')

      html = described_class.convert(document)

      expect(html).to include('<ol')
      expect(html).to include('start="3"')
      expect(html).to include('<li><p>Third item</p></li>')
      expect(html).to include('<li><p>Fourth item</p></li>')
    end

    it 'converts blockquotes to HTML' do
      document = Prosereflect::Document.new
      quote = document.add_blockquote
      quote.citation = 'https://example.com/source'

      quote.add_paragraph('This is a quoted text.')
      quote.add_paragraph('With multiple paragraphs.')

      html = described_class.convert(document)

      expect(html).to include('<blockquote')
      expect(html).to include('cite="https://example.com/source"')
      expect(html).to include('<p>This is a quoted text.</p>')
      expect(html).to include('<p>With multiple paragraphs.</p>')
    end

    it 'converts horizontal rules to HTML' do
      document = Prosereflect::Document.new
      hr = document.add_horizontal_rule
      hr.style = 'dashed'
      hr.width = '80%'
      hr.thickness = 2

      html = described_class.convert(document)

      expect(html).to include('<hr')
      expect(html).to include('style="border-style: dashed; width: 80%; border-width: 2px"')
    end

    it 'converts code blocks to HTML' do
      document = Prosereflect::Document.new
      wrapper = document.add_code_block_wrapper
      wrapper.line_numbers = true
      wrapper.highlight_lines = [1, 3]

      code_block = wrapper.add_code_block
      code_block.language = 'ruby'
      code_block.content = "def example\n  puts 'Hello'\nend"

      html = described_class.convert(document)

      expect(html).to include('<pre')
      expect(html).to include('data-line-numbers="true"')
      expect(html).to include('data-highlight-lines="1,3"')
      expect(html).to include('<code')
      expect(html).to include('class="language-ruby"')
      expect(html).to include("def example\n  puts 'Hello'\nend")
    end

    it 'converts text with all mark types' do
      document = Prosereflect::Document.new
      paragraph = document.add_paragraph

      paragraph.add_text('struck', [Prosereflect::Mark::Strike.new])
      paragraph.add_text(' and ')
      paragraph.add_text('underlined', [Prosereflect::Mark::Underline.new])
      paragraph.add_text(' and ')
      paragraph.add_text('sub', [Prosereflect::Mark::Subscript.new])
      paragraph.add_text(' and ')
      paragraph.add_text('super', [Prosereflect::Mark::Superscript.new])

      html = described_class.convert(document)

      expect(html).to include('<del>struck</del>')
      expect(html).to include('<u>underlined</u>')
      expect(html).to include('<sub>sub</sub>')
      expect(html).to include('<sup>super</sup>')
    end

    it 'converts complex table headers' do
      document = Prosereflect::Document.new
      table = document.add_table

      # Add header row with complex cells
      header = table.add_header(['Product'])
      header.cells.first.scope = 'col'
      header.cells.first.abbr = 'Prod'
      header.cells.first.colspan = 2

      html = described_class.convert(document)

      expect(html).to include('<thead>')
      expect(html).to include('<th')
      expect(html).to include('scope="col"')
      expect(html).to include('abbr="Prod"')
      expect(html).to include('colspan="2"')
    end

    it 'handles complex nested structures' do
      document = Prosereflect::Document.new

      # Add a paragraph with styled text
      document.add_paragraph('Paragraph 1')

      # Add a paragraph with mixed styling
      p2 = document.add_paragraph
      p2.add_text('Paragraph ')
      p2.add_text('2', [Prosereflect::Mark::Bold.new])

      # Add a table
      table = document.add_table
      table.add_row(['Cell 1', 'Cell 2'])

      html = described_class.convert(document)

      expect(html).to include('Paragraph 1')
      expect(html).to include('Paragraph')
      expect(html).to include('<strong>2</strong>')
      expect(html).to include('<table>')
      expect(html).to include('Cell 1')
      expect(html).to include('Cell 2')
    end

    it 'handles round-trip conversion from HTML to model and back' do
      original_html = '<p>This is a <strong>test</strong> paragraph with <em>styling</em>.</p>'

      # HTML to model
      document = Prosereflect::Input::Html.parse(original_html)

      # Model back to HTML
      result_html = described_class.convert(document)

      # The exact HTML may differ in formatting, but the content should be preserved
      expect(result_html).to include('This is a <strong>test</strong> paragraph with <em>styling</em>')
    end

    it 'converts headings to HTML' do
      document = Prosereflect::Document.new

      # Add h1
      h1 = Prosereflect::Heading.new
      h1.level = 1
      h1.add_text('Main Title')
      document.add_child(h1)

      # Add h2
      h2 = Prosereflect::Heading.new
      h2.level = 2
      h2.add_text('Subtitle')
      document.add_child(h2)

      # Add h3 with styled text
      h3 = Prosereflect::Heading.new
      h3.level = 3
      text = Prosereflect::Text.new(text: 'Important')
      text.marks = [Prosereflect::Mark::Bold.new]
      h3.add_child(text)
      document.add_child(h3)

      html = described_class.convert(document)

      expect(html).to include('<h1>Main Title</h1>')
      expect(html).to include('<h2>Subtitle</h2>')
      expect(html).to include('<h3><strong>Important</strong></h3>')
    end
  end
end
