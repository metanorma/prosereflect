# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Prosereflect::Output::Html do
  describe '.convert' do
    it 'converts a simple document to HTML' do
      document = Prosereflect::Document.new
      document.add_paragraph('This is a test paragraph.')

      html = described_class.convert(document)
      expect(html).to eq('<p>This is a test paragraph.</p>')
    end

    it 'renders basic styled text correctly' do
      document = Prosereflect::Document.new
      paragraph = document.add_paragraph
      paragraph.add_text('This is ')

      bold_text = Prosereflect::Text.new(text: 'bold')
      bold_text.marks = [Prosereflect::Mark::Bold.new]
      paragraph.add_child(bold_text)

      paragraph.add_text(' and ')

      italic_text = Prosereflect::Text.new(text: 'italic')
      italic_text.marks = [Prosereflect::Mark::Italic.new]
      paragraph.add_child(italic_text)

      paragraph.add_text(' text.')

      html = described_class.convert(document)
      expect(html).to eq('<p>This is <strong>bold</strong> and <em>italic</em> text.</p>')
    end

    it 'renders headings with mixed content correctly' do
      document = Prosereflect::Document.new
      heading = Prosereflect::Heading.new
      heading.level = 1
      heading.add_text('Title with ')

      bold_text = Prosereflect::Text.new(text: 'bold')
      bold_text.marks = [Prosereflect::Mark::Bold.new]
      heading.add_child(bold_text)

      heading.add_text(' and ')

      link_text = Prosereflect::Text.new(text: 'link')
      link_mark = Prosereflect::Mark::Link.new
      link_mark.attrs = { 'href' => 'https://example.com' }
      link_text.marks = [link_mark]
      heading.add_child(link_text)

      document.add_child(heading)

      html = described_class.convert(document)
      expect(html).to eq('<h1>Title with <strong>bold</strong> and <a href="https://example.com">link</a></h1>')
    end

    it 'renders lists with nested content correctly' do
      document = Prosereflect::Document.new
      list = Prosereflect::BulletList.new

      # First item with emphasis
      item1 = Prosereflect::ListItem.new
      para1 = item1.add_paragraph
      para1.add_text('First item with ')
      em_text = Prosereflect::Text.new(text: 'emphasis')
      em_text.marks = [Prosereflect::Mark::Italic.new]
      para1.add_child(em_text)
      list.add_child(item1)

      # Second item with code
      item2 = Prosereflect::ListItem.new
      para2 = item2.add_paragraph
      para2.add_text('Second item with ')
      code_text = Prosereflect::Text.new(text: 'code')
      code_text.marks = [Prosereflect::Mark::Code.new]
      para2.add_child(code_text)
      list.add_child(item2)

      document.add_child(list)

      html = described_class.convert(document)
      expect(html).to eq('<ul><li><p>First item with <em>emphasis</em></p></li><li><p>Second item with <code>code</code></p></li></ul>')
    end

    it 'renders blockquotes with citations correctly' do
      document = Prosereflect::Document.new
      quote = Prosereflect::Blockquote.new
      quote.citation = 'https://example.com'

      para = quote.add_paragraph('A quote with ')
      bold_text = Prosereflect::Text.new(text: 'bold')
      bold_text.marks = [Prosereflect::Mark::Bold.new]
      para.add_child(bold_text)
      para.add_text(' text')

      document.add_child(quote)

      html = described_class.convert(document)
      expect(html).to eq('<blockquote cite="https://example.com"><p>A quote with <strong>bold</strong> text</p></blockquote>')
    end

    it 'renders code blocks with language correctly' do
      document = Prosereflect::Document.new
      wrapper = Prosereflect::CodeBlockWrapper.new

      code_block = wrapper.add_code_block
      code_block.language = 'ruby'
      code_block.content = "def example\n  puts \"Hello\"\nend"

      document.add_child(wrapper)

      expected = <<~HTML.strip
        <pre><code class="language-ruby">def example
          puts "Hello"
        end</code></pre>
      HTML

      html = described_class.convert(document)
      expect(html).to eq(expected.gsub(/^ {10}/, '  '))
    end

    it 'renders images with attributes correctly' do
      document = Prosereflect::Document.new
      image = Prosereflect::Image.new
      image.src = 'test.jpg'
      image.alt = 'Test image'
      image.title = 'Test title'
      image.width = 800
      image.height = 600

      document.add_child(image)

      html = described_class.convert(document)
      expect(html).to eq('<img src="test.jpg" alt="Test image" title="Test title" width="800" height="600">')
    end

    it 'renders horizontal rules with styles correctly' do
      document = Prosereflect::Document.new
      hr = Prosereflect::HorizontalRule.new
      hr.style = 'dashed'
      hr.width = '80%'
      hr.thickness = 2

      document.add_child(hr)

      html = described_class.convert(document)
      expect(html).to eq('<hr style="border-style: dashed; width: 80%; border-width: 2px">')
    end

    it 'renders complex nested structures correctly' do
      document = Prosereflect::Document.new

      # Add heading
      heading = Prosereflect::Heading.new
      heading.level = 2
      heading.add_text('Features')
      document.add_child(heading)

      # Add list with nested content
      list = Prosereflect::BulletList.new

      # List item with blockquote
      item1 = Prosereflect::ListItem.new
      para1 = item1.add_paragraph
      para1.add_text('Quote: ')
      list.add_child(item1)

      quote = Prosereflect::Blockquote.new
      quote.citation = 'https://example.com'
      quote.add_paragraph('Nested quote')
      list.add_child(quote)

      # List item with code
      item2 = Prosereflect::ListItem.new
      para2 = item2.add_paragraph
      para2.add_text('Code: ')
      list.add_child(item2)

      wrapper = Prosereflect::CodeBlockWrapper.new
      code_block = wrapper.add_code_block
      code_block.language = 'ruby'
      code_block.content = 'puts "Hello"'
      list.add_child(wrapper)

      document.add_child(list)

      html = described_class.convert(document)
      expected = '<h2>Features</h2>' \
                '<ul>' \
                '<li><p>Quote: </p></li>' \
                '<li><blockquote cite="https://example.com"><p>Nested quote</p></blockquote></li>' \
                '<li><p>Code: </p></li>' \
                '<li><pre><code class="language-ruby">puts "Hello"</code></pre></li>' \
                '</ul>'
      expect(html).to eq(expected)
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
      expected = '<table>' \
                '<thead><tr><th>Header 1</th><th>Header 2</th></tr></thead>' \
                '<tbody>' \
                '<tr><td>Row 1, Cell 1</td><td>Row 1, Cell 2</td></tr>' \
                '<tr><td>Row 2, Cell 1</td><td>Row 2, Cell 2</td></tr>' \
                '</tbody>' \
                '</table>'
      expect(html).to eq(expected)
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
      expected = '<table><thead><tr><th scope="col" abbr="Prod" colspan="2">Product</th></tr></thead><tbody></tbody></table>'
      expect(html).to eq(expected)
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
      expect(html).to eq('<p><del>struck</del> and <u>underlined</u> and <sub>sub</sub> and <sup>super</sup></p>')
    end

    it 'converts images with all attributes' do
      document = Prosereflect::Document.new
      image = document.add_image('example.jpg', 'Example image')
      image.title = 'Image tooltip'
      image.width = 800
      image.height = 600

      html = described_class.convert(document)
      expect(html).to eq('<img src="example.jpg" alt="Example image" title="Image tooltip" width="800" height="600">')
    end

    it 'converts code blocks with wrapper attributes' do
      document = Prosereflect::Document.new
      wrapper = document.add_code_block_wrapper
      wrapper.line_numbers = true

      code_block = wrapper.add_code_block
      code_block.language = 'ruby'
      code_block.content = "def example\n  puts 'Hello'\nend"

      html = described_class.convert(document)
      expected = '<pre data-line-numbers="true"><code class="language-ruby">def example
  puts \'Hello\'
end</code></pre>'
      expect(html).to eq(expected)
    end

    it 'handles complex nested structures with tables' do
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
      expected = '<p>Paragraph 1</p><p>Paragraph <strong>2</strong></p><table><tbody><tr><td>Cell 1</td><td>Cell 2</td></tr></tbody></table>'
      expect(html).to eq(expected)
    end

    it 'renders user mentions correctly' do
      document = Prosereflect::Document.new
      user = Prosereflect::User.new
      user.id = '123'
      document.add_child(user)

      html = described_class.convert(document)
      expect(html).to eq('<user-mention data-id="123"></user-mention>')
    end

    it 'renders user mentions in paragraphs' do
      document = Prosereflect::Document.new
      paragraph = document.add_paragraph
      paragraph.add_text('Hello ')

      user = Prosereflect::User.new
      user.id = '123'
      paragraph.add_child(user)

      paragraph.add_text('!')

      html = described_class.convert(document)
      expect(html).to eq('<p>Hello <user-mention data-id="123"></user-mention>!</p>')
    end

    it 'renders multiple user mentions' do
      document = Prosereflect::Document.new
      paragraph = document.add_paragraph
      paragraph.add_text('Mentioned: ')

      user1 = Prosereflect::User.new
      user1.id = '123'
      paragraph.add_child(user1)

      paragraph.add_text(' and ')

      user2 = Prosereflect::User.new
      user2.id = '456'
      paragraph.add_child(user2)

      html = described_class.convert(document)
      expect(html).to eq('<p>Mentioned: <user-mention data-id="123"></user-mention> and <user-mention data-id="456"></user-mention></p>')
    end

    it 'renders user mentions with other marks' do
      document = Prosereflect::Document.new
      paragraph = document.add_paragraph

      bold_text = Prosereflect::Text.new(text: 'Bold')
      bold_text.marks = [Prosereflect::Mark::Bold.new]
      paragraph.add_child(bold_text)

      paragraph.add_text(' and ')

      user = Prosereflect::User.new
      user.id = '123'
      paragraph.add_child(user)

      paragraph.add_text(' and ')

      italic_text = Prosereflect::Text.new(text: 'italic')
      italic_text.marks = [Prosereflect::Mark::Italic.new]
      paragraph.add_child(italic_text)

      html = described_class.convert(document)
      expect(html).to eq('<p><strong>Bold</strong> and <user-mention data-id="123"></user-mention> and <em>italic</em></p>')
    end
  end
end
