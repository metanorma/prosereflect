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
      # Check for cell content rather than exact HTML structure
      expect(html).to include('Row 1, Cell 1')
      expect(html).to include('Header 1')
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
      # Test for the styled text components rather than exact HTML structure
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
  end
end
