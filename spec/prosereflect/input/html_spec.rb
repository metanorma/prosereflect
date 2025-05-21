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
      html = '<p><a href="https://example.com">Visit Example</a></p>'
      document = described_class.parse(html)

      paragraph = document.content.first
      link_text = paragraph.content.first

      expect(link_text.text).to eq('Visit Example')
      expect(link_text.marks.first.type).to eq('link')
      expect(link_text.marks.first.attrs[:href]).to eq('https://example.com')
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
      expect(document.content[0].text_content).to eq('Paragraph 1')
      expect(document.content[1].text_content).to eq('Paragraph 2')
    end
  end
end
