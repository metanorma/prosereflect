# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Prosereflect::Input::Html do
  describe '.parse' do
    it 'parses simple HTML into a document' do
      html = '<p>This is a test paragraph.</p>'
      document = described_class.parse(html)

      expect(document).to be_a(Prosereflect::Document)
      expect(document.content.size).to eq(1)
      expect(document.content.first).to be_a(Prosereflect::Paragraph)
      expect(document.content.first.text_content).to eq('This is a test paragraph.')
    end

    it 'parses HTML with styled text' do
      html = '<p>This is <strong>bold</strong> and <em>italic</em> text.</p>'
      document = described_class.parse(html)

      paragraph = document.content.first
      expect(paragraph.content.size).to eq(5) # "This is ", bold, " and ", italic, " text."

      # Check bold text
      bold_text = paragraph.content[1]
      expect(bold_text.text).to eq('bold')
      expect(bold_text.marks.first.type).to eq('bold')

      # Check italic text
      italic_text = paragraph.content[3]
      expect(italic_text.text).to eq('italic')
      expect(italic_text.marks.first.type).to eq('italic')
    end

    it 'parses strike text' do
      html = '<p>This is <strike>struck through</strike> text and <s>this too</s> and <del>deleted</del>.</p>'
      document = described_class.parse(html)

      paragraph = document.content.first
      expect(paragraph.content.size).to eq(7) # "This is ", strike, " text and ", strike, " and ", strike, "."

      # Check first strike
      strike_text = paragraph.content[1]
      expect(strike_text.text).to eq('struck through')
      expect(strike_text.marks.first.type).to eq('strike')

      # Check second strike (s tag)
      strike_text2 = paragraph.content[3]
      expect(strike_text2.text).to eq('this too')
      expect(strike_text2.marks.first.type).to eq('strike')

      # Check third strike (del tag)
      strike_text3 = paragraph.content[5]
      expect(strike_text3.text).to eq('deleted')
      expect(strike_text3.marks.first.type).to eq('strike')
    end

    it 'parses subscript text' do
      html = '<p>H<sub>2</sub>O and E = mc<sub>2</sub></p>'
      document = described_class.parse(html)

      paragraph = document.content.first
      expect(paragraph.content.size).to eq(4) # "H", sub, "O and E = mc", sub

      # Check subscripts
      sub_text1 = paragraph.content[1]
      expect(sub_text1.text).to eq('2')
      expect(sub_text1.marks.first.type).to eq('subscript')

      sub_text2 = paragraph.content[3]
      expect(sub_text2.text).to eq('2')
      expect(sub_text2.marks.first.type).to eq('subscript')
    end

    it 'parses superscript text' do
      html = '<p>x<sup>2</sup> + y<sup>2</sup> = z<sup>2</sup></p>'
      document = described_class.parse(html)

      paragraph = document.content.first
      expect(paragraph.content.size).to eq(6) # "x", sup, " + y", sup, " = z", sup

      # Check superscripts
      sup_text = paragraph.content[1]
      expect(sup_text.text).to eq('2')
      expect(sup_text.marks.first.type).to eq('superscript')

      sup_text2 = paragraph.content[3]
      expect(sup_text2.text).to eq('2')
      expect(sup_text2.marks.first.type).to eq('superscript')

      sup_text3 = paragraph.content[5]
      expect(sup_text3.text).to eq('2')
      expect(sup_text3.marks.first.type).to eq('superscript')
    end

    it 'parses underlined text' do
      html = '<p>This is <u>underlined</u> text.</p>'
      document = described_class.parse(html)

      paragraph = document.content.first
      expect(paragraph.content.size).to eq(3) # "This is ", underline, " text."

      # Check underline
      underline_text = paragraph.content[1]
      expect(underline_text.text).to eq('underlined')
      expect(underline_text.marks.first.type).to eq('underline')
    end

    it 'handles mixed text styles' do
      html = '<p><strong><u>Bold and underlined</u></strong> and <em><strike>italic struck</strike></em></p>'
      document = described_class.parse(html)

      paragraph = document.content.first
      expect(paragraph.content.size).to eq(3) # bold+underline, " and ", italic+strike

      # Check bold and underlined text
      bold_underline = paragraph.content[0]
      expect(bold_underline.text).to eq('Bold and underlined')
      expect(bold_underline.marks.map(&:type)).to contain_exactly('bold', 'underline')

      # Check italic and struck text
      italic_strike = paragraph.content[2]
      expect(italic_strike.text).to eq('italic struck')
      expect(italic_strike.marks.map(&:type)).to contain_exactly('italic', 'strike')
    end

    it 'handles complex mixed text styles' do
      html = '<p>x<sup>2</sup> + <u>y<sub>1</sub></u> = <strike>z<sup>n</sup></strike></p>'
      document = described_class.parse(html)

      paragraph = document.content.first

      # Check superscript
      sup_text = paragraph.content[1]
      expect(sup_text.text).to eq('2')
      expect(sup_text.marks.map(&:type)).to contain_exactly('superscript')

      # Check underlined text with subscript
      underline_text = paragraph.content[3]
      expect(underline_text.text).to eq('y')
      expect(underline_text.marks.map(&:type)).to contain_exactly('underline')

      sub_text = paragraph.content[4]
      expect(sub_text.text).to eq('1')
      expect(sub_text.marks.map(&:type)).to contain_exactly('underline', 'subscript')

      # Check struck text with superscript
      strike_text = paragraph.content[6]
      expect(strike_text.text).to eq('z')
      expect(strike_text.marks.map(&:type)).to contain_exactly('strike')

      sup_text2 = paragraph.content[7]
      expect(sup_text2.text).to eq('n')
      expect(sup_text2.marks.map(&:type)).to contain_exactly('strike', 'superscript')
    end

    it 'parses HTML tables' do
      html = <<~HTML
        <table>
          <tr>
            <td>Row 1, Cell 1</td>
            <td>Row 1, Cell 2</td>
          </tr>
          <tr>
            <td>Row 2, Cell 1</td>
            <td>Row 2, Cell 2</td>
          </tr>
        </table>
      HTML

      document = described_class.parse(html)

      expect(document.content.size).to eq(1)
      expect(document.content.first).to be_a(Prosereflect::Table)

      table = document.content.first
      expect(table.content.size).to eq(2) # 2 rows

      first_row = table.content.first
      expect(first_row).to be_a(Prosereflect::TableRow)
      expect(first_row.content.size).to eq(2) # 2 cells

      first_cell = first_row.content.first
      expect(first_cell).to be_a(Prosereflect::TableCell)
      expect(first_cell.text_content).to eq('Row 1, Cell 1')
    end

    it 'parses HTML links' do
      html = '<p>This is a <a href="https://example.com">link</a></p>'
      doc = described_class.parse(html)

      paragraph = doc.content.first
      link_text = paragraph.content[1] # "This is a ", "link"
      expect(link_text).to be_a(Prosereflect::Text)
      expect(link_text.text).to eq('link')
      expect(link_text.marks.first.type).to eq('link')
      expect(link_text.marks.first.attrs['href']).to eq('https://example.com')
    end

    it 'handles line breaks' do
      html = '<p>Line 1<br>Line 2</p>'
      document = described_class.parse(html)

      paragraph = document.content.first
      expect(paragraph.content.size).to eq(3) # "Line 1", br, "Line 2"
      expect(paragraph.content[1]).to be_a(Prosereflect::HardBreak)
    end

    it 'handles nested HTML structures' do
      html = <<~HTML
        <div>
          <p>Paragraph 1</p>
          <p>Paragraph <strong>2</strong></p>
        </div>
      HTML

      document = described_class.parse(html)

      expect(document.content.size).to eq(2) # 2 paragraphs
      expect(document.content[0]).to be_a(Prosereflect::Paragraph)
      expect(document.content[1]).to be_a(Prosereflect::Paragraph)
      expect(document.content[0].text_content).to eq('Paragraph 1')
      expect(document.content[1].text_content).to eq('Paragraph 2')
    end

    it 'parses ordered lists' do
      html = <<~HTML
        <ol start="3">
          <li>Third item</li>
          <li>Fourth item</li>
        </ol>
      HTML

      document = described_class.parse(html)

      expect(document.content.size).to eq(1)
      list = document.content.first
      expect(list).to be_a(Prosereflect::OrderedList)
      expect(list.start).to eq(3)
      expect(list.items.size).to eq(2)

      first_item = list.items.first
      expect(first_item).to be_a(Prosereflect::ListItem)
      expect(first_item.text_content).to eq('Third item')
    end

    it 'parses bullet lists with different styles' do
      html = <<~HTML
        <ul style="list-style-type: square">
          <li>First bullet</li>
          <li>Second bullet</li>
        </ul>
      HTML

      document = described_class.parse(html)

      expect(document.content.size).to eq(1)
      list = document.content.first
      expect(list).to be_a(Prosereflect::BulletList)
      expect(list.bullet_style).to eq('square')
      expect(list.items.size).to eq(2)

      second_item = list.items.last
      expect(second_item).to be_a(Prosereflect::ListItem)
      expect(second_item.text_content).to eq('Second bullet')
    end

    it 'parses nested lists' do
      html = <<~HTML
        <ul>
          <li>First level
            <ol start="1">
              <li>Nested item 1</li>
              <li>Nested item 2</li>
            </ol>
          </li>
          <li>Another item</li>
        </ul>
      HTML

      document = described_class.parse(html)

      expect(document.content.size).to eq(1)
      outer_list = document.content.first
      expect(outer_list).to be_a(Prosereflect::BulletList)
      expect(outer_list.items.size).to eq(2)

      first_item = outer_list.items.first
      expect(first_item.content.size).to eq(2) # text and nested list
      nested_list = first_item.content.last
      expect(nested_list).to be_a(Prosereflect::OrderedList)
      expect(nested_list.items.size).to eq(2)
    end

    it 'parses blockquotes with citation' do
      html = <<~HTML
        <blockquote cite="https://example.com/source">
          <p>This is a quoted text.</p>
          <p>With multiple paragraphs.</p>
        </blockquote>
      HTML

      document = described_class.parse(html)

      expect(document.content.size).to eq(1)
      quote = document.content.first
      expect(quote).to be_a(Prosereflect::Blockquote)
      expect(quote.citation).to eq('https://example.com/source')
      expect(quote.blocks.size).to eq(2)
      expect(quote.blocks.first.text_content).to eq('This is a quoted text.')
    end

    it 'parses horizontal rules with styles' do
      html = '<hr style="border-style: dashed; width: 80%; border-width: 2px">'
      document = described_class.parse(html)

      expect(document.content.size).to eq(1)
      hr = document.content.first
      expect(hr).to be_a(Prosereflect::HorizontalRule)
      expect(hr.style).to eq('dashed')
      expect(hr.width).to eq('80%')
      expect(hr.thickness).to eq(2)
    end

    it 'handles mixed content with all node types' do
      html = <<~HTML
        <div>
          <p>Introduction paragraph</p>
          <ul>
            <li>List item 1</li>
            <li>List item 2</li>
          </ul>
          <hr>
          <blockquote cite="Author">
            <p>A meaningful quote</p>
          </blockquote>
          <ol start="1">
            <li>First point</li>
            <li>Second point</li>
          </ol>
        </div>
      HTML

      document = described_class.parse(html)

      expect(document.content.size).to eq(5) # p, ul, hr, blockquote, ol
      expect(document.content[0]).to be_a(Prosereflect::Paragraph)
      expect(document.content[0].text_content).to eq('Introduction paragraph')

      expect(document.content[1]).to be_a(Prosereflect::BulletList)
      expect(document.content[1].items.size).to eq(2)

      expect(document.content[2]).to be_a(Prosereflect::HorizontalRule)

      expect(document.content[3]).to be_a(Prosereflect::Blockquote)
      expect(document.content[3].citation).to eq('Author')

      expect(document.content[4]).to be_a(Prosereflect::OrderedList)
      expect(document.content[4].items.size).to eq(2)
    end

    it 'parses table headers' do
      html = <<~HTML
        <table>
          <tr>
            <th>Header 1</th>
            <th scope="col">Header 2</th>
            <th scope="col" abbr="H3" colspan="2">Header 3</th>
          </tr>
          <tr>
            <td>Data 1</td>
            <td>Data 2</td>
            <td>Data 3</td>
          </tr>
        </table>
      HTML

      doc = described_class.parse(html)
      table = doc.tables.first
      header_row = table.rows.first

      # Check header cells
      expect(header_row.cells.size).to eq(3)
      expect(header_row.cells.all? { |cell| cell.is_a?(Prosereflect::TableHeader) }).to be true

      # Check first header
      header1 = header_row.cells[0]
      expect(header1.text_content).to eq('Header 1')
      expect(header1.scope).to be_nil

      # Check second header
      header2 = header_row.cells[1]
      expect(header2.text_content).to eq('Header 2')
      expect(header2.scope).to eq('col')

      # Check third header with all attributes
      header3 = header_row.cells[2]
      expect(header3.text_content).to eq('Header 3')
      expect(header3.scope).to eq('col')
      expect(header3.abbr).to eq('H3')
      expect(header3.colspan).to eq(2)
    end

    it 'parses tables with mixed header types' do
      html = <<~HTML
        <table>
          <tr>
            <th scope="row">Row Header</th>
            <td>Data 1</td>
            <td>Data 2</td>
          </tr>
          <tr>
            <th scope="row">Another Row Header</th>
            <td>Data 3</td>
            <td>Data 4</td>
          </tr>
        </table>
      HTML

      doc = described_class.parse(html)
      table = doc.tables.first

      # Check first row
      first_row = table.rows[0]
      expect(first_row.cells[0]).to be_a(Prosereflect::TableHeader)
      expect(first_row.cells[0].scope).to eq('row')
      expect(first_row.cells[0].text_content).to eq('Row Header')
      expect(first_row.cells[1]).to be_a(Prosereflect::TableCell)
      expect(first_row.cells[2]).to be_a(Prosereflect::TableCell)

      # Check second row
      second_row = table.rows[1]
      expect(second_row.cells[0]).to be_a(Prosereflect::TableHeader)
      expect(second_row.cells[0].scope).to eq('row')
      expect(second_row.cells[0].text_content).to eq('Another Row Header')
    end

    it 'parses complex table structures with headers' do
      html = <<~HTML
        <table>
          <thead>
            <tr>
              <th scope="col" colspan="2">Product Info</th>
              <th scope="col">Price</th>
            </tr>
            <tr>
              <th scope="col">Name</th>
              <th scope="col">Description</th>
              <th scope="col" abbr="$">Amount</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <th scope="row">Widget</th>
              <td>A fantastic widget</td>
              <td>$10.00</td>
            </tr>
            <tr>
              <th scope="row">Gadget</th>
              <td>An amazing gadget</td>
              <td>$15.00</td>
            </tr>
          </tbody>
        </table>
      HTML

      doc = described_class.parse(html)
      table = doc.tables.first
      rows = table.rows

      # Check first header row
      first_row = rows[0]
      expect(first_row.cells[0]).to be_a(Prosereflect::TableHeader)
      expect(first_row.cells[0].colspan).to eq(2)
      expect(first_row.cells[0].scope).to eq('col')
      expect(first_row.cells[0].text_content).to eq('Product Info')
      expect(first_row.cells[1]).to be_a(Prosereflect::TableHeader)
      expect(first_row.cells[1].scope).to eq('col')
      expect(first_row.cells[1].text_content).to eq('Price')

      # Check second header row
      second_row = rows[1]
      expect(second_row.cells.all? { |cell| cell.is_a?(Prosereflect::TableHeader) }).to be true
      expect(second_row.cells[2].abbr).to eq('$')

      # Check data rows with row headers
      data_rows = rows[2..3]
      data_rows.each do |row|
        expect(row.cells[0]).to be_a(Prosereflect::TableHeader)
        expect(row.cells[0].scope).to eq('row')
        expect(row.cells[1]).to be_a(Prosereflect::TableCell)
        expect(row.cells[2]).to be_a(Prosereflect::TableCell)
      end
    end

    describe 'heading handling' do
      it 'parses h1-h6 tags' do
        html = <<~HTML
          <h1>Title</h1>
          <h2>Subtitle</h2>
          <h3>Section</h3>
          <h4>Subsection</h4>
          <h5>Detail</h5>
          <h6>Fine Detail</h6>
        HTML

        doc = described_class.parse(html)

        expect(doc.content.size).to eq(6)
        doc.content.each_with_index do |heading, index|
          expect(heading).to be_a(Prosereflect::Heading)
          expect(heading.level).to eq(index + 1)
        end

        expect(doc.content[0].text_content).to eq('Title')
        expect(doc.content[1].text_content).to eq('Subtitle')
        expect(doc.content[2].text_content).to eq('Section')
        expect(doc.content[3].text_content).to eq('Subsection')
        expect(doc.content[4].text_content).to eq('Detail')
        expect(doc.content[5].text_content).to eq('Fine Detail')
      end

      it 'parses headings with styled text' do
        html = '<h1>This is <strong>bold</strong> and <em>italic</em></h1>'
        doc = described_class.parse(html)

        heading = doc.content.first
        expect(heading).to be_a(Prosereflect::Heading)
        expect(heading.level).to eq(1)
        expect(heading.content.size).to eq(4)

        expect(heading.content[0]).to be_a(Prosereflect::Text)
        expect(heading.content[0].text).to eq('This is ')

        expect(heading.content[1]).to be_a(Prosereflect::Text)
        expect(heading.content[1].text).to eq('bold')
        expect(heading.content[1].marks.first.type).to eq('bold')

        expect(heading.content[2]).to be_a(Prosereflect::Text)
        expect(heading.content[2].text).to eq(' and ')

        expect(heading.content[3]).to be_a(Prosereflect::Text)
        expect(heading.content[3].text).to eq('italic')
        expect(heading.content[3].marks.first.type).to eq('italic')
      end

      it 'handles nested content in headings' do
        html = '<h2>Title with <a href="https://example.com">link</a></h2>'
        doc = described_class.parse(html)

        heading = doc.content.first
        expect(heading).to be_a(Prosereflect::Heading)
        expect(heading.level).to eq(2)
        expect(heading.content.size).to eq(2)

        expect(heading.content[0]).to be_a(Prosereflect::Text)
        expect(heading.content[0].text).to eq('Title with ')

        expect(heading.content[1]).to be_a(Prosereflect::Text)
        expect(heading.content[1].text).to eq('link')
        expect(heading.content[1].marks.first.type).to eq('link')
        expect(heading.content[1].marks.first.attrs['href']).to eq('https://example.com')
      end
    end
  end

  describe 'image handling' do
    it 'parses basic image with src' do
      html = '<img src="example.jpg">'
      doc = described_class.parse(html)

      expect(doc.content.size).to eq(1)
      image = doc.content.first
      expect(image).to be_a(Prosereflect::Image)
      expect(image.src).to eq('example.jpg')
    end

    it 'parses image with alt and title' do
      html = '<img src="example.jpg" alt="Example image" title="Image tooltip">'
      doc = described_class.parse(html)

      image = doc.content.first
      expect(image.alt).to eq('Example image')
      expect(image.title).to eq('Image tooltip')
    end

    it 'parses image with dimensions' do
      html = '<img src="example.jpg" width="800" height="600">'
      doc = described_class.parse(html)

      image = doc.content.first
      expect(image.width).to eq(800)
      expect(image.height).to eq(600)
    end

    it 'handles image within paragraph' do
      html = '<p>Before <img src="example.jpg" alt="Example"> After</p>'
      doc = described_class.parse(html)

      expect(doc.content.size).to eq(1)
      paragraph = doc.content.first
      expect(paragraph).to be_a(Prosereflect::Paragraph)
      expect(paragraph.content.size).to eq(3)

      expect(paragraph.content[0]).to be_a(Prosereflect::Text)
      expect(paragraph.content[0].text).to eq('Before ')

      expect(paragraph.content[1]).to be_a(Prosereflect::Image)
      expect(paragraph.content[1].src).to eq('example.jpg')
      expect(paragraph.content[1].alt).to eq('Example')

      expect(paragraph.content[2]).to be_a(Prosereflect::Text)
      expect(paragraph.content[2].text).to eq(' After')
    end

    it 'handles multiple images in sequence' do
      html = '<img src="first.jpg"><img src="second.jpg">'
      doc = described_class.parse(html)

      expect(doc.content.size).to eq(2)
      expect(doc.content[0]).to be_a(Prosereflect::Image)
      expect(doc.content[0].src).to eq('first.jpg')
      expect(doc.content[1]).to be_a(Prosereflect::Image)
      expect(doc.content[1].src).to eq('second.jpg')
    end

    it 'ignores image without src attribute' do
      html = '<img alt="No source">'
      doc = described_class.parse(html)

      expect(doc.content).to be_empty
    end
  end

  describe 'code handling' do
    it 'parses simple code block' do
      html = '<pre><code>puts "Hello, World!"</code></pre>'
      doc = described_class.parse(html)

      expect(doc.content.size).to eq(1)
      wrapper = doc.content.first
      expect(wrapper).to be_a(Prosereflect::CodeBlockWrapper)

      code_blocks = wrapper.code_blocks
      expect(code_blocks.size).to eq(1)
      expect(code_blocks.first.content).to eq('puts "Hello, World!"')
    end

    it 'parses code block with language' do
      html = '<pre><code class="language-ruby">def hello\n  puts "Hello"\nend</code></pre>'
      doc = described_class.parse(html)

      wrapper = doc.content.first
      code_block = wrapper.code_blocks.first
      expect(code_block.language).to eq('ruby')
      expect(code_block.content).to eq('def hello\n  puts "Hello"\nend')
    end

    it 'parses code block with line numbers' do
      html = '<pre data-line-numbers="true"><code>Line 1\nLine 2</code></pre>'
      doc = described_class.parse(html)

      wrapper = doc.content.first
      expect(wrapper.line_numbers).to be true
      expect(wrapper.code_blocks.first.content).to eq('Line 1\nLine 2')
    end

    it 'parses code block with highlight lines' do
      html = '<pre data-highlight-lines="1,3"><code>Line 1\nLine 2\nLine 3</code></pre>'
      doc = described_class.parse(html)

      wrapper = doc.content.first
      expect(wrapper.highlight_lines).to eq([1, 3])
    end

    it 'handles multiple code blocks in one pre' do
      html = <<~HTML
        <pre>
          <code class="language-ruby">puts "Ruby"</code>
          <code class="language-python">print("Python")</code>
        </pre>
      HTML
      doc = described_class.parse(html)

      wrapper = doc.content.first
      code_blocks = wrapper.code_blocks
      expect(code_blocks.size).to eq(2)

      expect(code_blocks[0].language).to eq('ruby')
      expect(code_blocks[0].content).to eq('puts "Ruby"')

      expect(code_blocks[1].language).to eq('python')
      expect(code_blocks[1].content).to eq('print("Python")')
    end

    it 'handles inline code differently from code blocks' do
      html = '<p>This is <code>inline code</code> and a block:</p><pre><code>block code</code></pre>'
      doc = described_class.parse(html)

      expect(doc.content.size).to eq(2)

      # Check inline code
      paragraph = doc.content[0]
      inline_code = paragraph.content[1]
      expect(inline_code.marks.first.type).to eq('code')
      expect(inline_code.text).to eq('inline code')

      # Check block code
      wrapper = doc.content[1]
      expect(wrapper).to be_a(Prosereflect::CodeBlockWrapper)
      expect(wrapper.code_blocks.first.content).to eq('block code')
    end

    it 'preserves whitespace in code blocks' do
      html = <<~HTML
                <pre><code>def example
          indented_line
        end</code></pre>
      HTML
      doc = described_class.parse(html)

      code_block = doc.content.first.code_blocks.first
      expect(code_block.content).to eq("def example\n  indented_line\nend")
    end

    it 'handles code block attributes' do
      html = '<pre><code class="language-ruby">code</code></pre>'
      doc = described_class.parse(html)

      code_block = doc.content.first.code_blocks.first
      expect(code_block.language).to eq('ruby')

      # Test attribute writers
      code_block.language = 'python'
      expect(code_block.language).to eq('python')

      code_block.line_numbers = true
      expect(code_block.line_numbers).to be true

      code_block.highlight_lines = [1, 3, 5]
      expect(code_block.highlight_lines).to eq([1, 3, 5])

      # Test hash representation
      hash = code_block.to_h
      expect(hash['attrs']['language']).to eq('python')
      expect(hash['attrs']['line_numbers']).to be true
      expect(hash['attrs']['highlight_lines']).to eq('1,3,5')
    end

    it 'handles code block attributes hash' do
      html = '<pre><code class="language-ruby">code</code></pre>'
      doc = described_class.parse(html)

      code_block = doc.content.first.code_blocks.first
      code_block.language = 'python'
      code_block.line_numbers = true
      code_block.highlight_lines = [1, 3, 5]

      attrs = code_block.attributes
      expect(attrs[:language]).to eq('python')
      expect(attrs[:line_numbers]).to be true
      expect(attrs[:highlight_lines]).to eq([1, 3, 5])
    end
  end
end
