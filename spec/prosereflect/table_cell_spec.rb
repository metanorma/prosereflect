# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Prosereflect::TableCell do
  describe 'initialization' do
    it 'initializes as a table_cell node' do
      cell = described_class.new({ 'type' => 'table_cell' })
      expect(cell.type).to eq('table_cell')
    end
  end

  describe '.create' do
    it 'creates an empty table cell' do
      cell = described_class.create
      expect(cell).to be_a(described_class)
      expect(cell.type).to eq('table_cell')
      expect(cell.content).to be_empty
    end

    it 'creates a table cell with attributes' do
      attrs = { 'colspan' => 2, 'rowspan' => 1 }
      cell = described_class.new(attrs: attrs)
      expect(cell.attrs).to eq(attrs)
    end
  end

  describe '#paragraphs' do
    it 'returns all paragraphs in the cell' do
      cell = described_class.create
      cell.add_paragraph('Para 1')
      cell.add_paragraph('Para 2')

      expect(cell.paragraphs.size).to eq(2)
      expect(cell.paragraphs).to all(be_a(Prosereflect::Paragraph))
    end

    it 'returns empty array for cell with no paragraphs' do
      cell = described_class.create
      expect(cell.paragraphs).to eq([])
    end
  end

  describe '#text_content' do
    it 'returns concatenated text from all paragraphs with newlines' do
      cell = described_class.create
      cell.add_paragraph('First paragraph')
      cell.add_paragraph('Second paragraph')

      expect(cell.text_content).to eq("First paragraph\nSecond paragraph")
    end

    it 'returns empty string for empty cell' do
      cell = described_class.create
      expect(cell.text_content).to eq('')
    end
  end

  describe '#lines' do
    it 'splits text content into lines' do
      cell = described_class.create
      cell.add_paragraph('Line 1')
      cell.add_paragraph('Line 2')

      expect(cell.lines).to eq(['Line 1', 'Line 2'])
    end

    it 'returns empty array for empty cell' do
      cell = described_class.create
      expect(cell.lines).to eq([])
    end

    it 'handles multi-line paragraphs' do
      cell = described_class.create
      para = cell.add_paragraph('First line')
      para.add_hard_break
      para.add_text('Second line')

      expect(cell.lines).to eq(['First line', 'Second line'])
    end
  end

  describe '#add_paragraph' do
    it 'adds a paragraph with text' do
      cell = described_class.create
      paragraph = cell.add_paragraph('Test content')

      expect(cell.paragraphs.size).to eq(1)
      expect(paragraph).to be_a(Prosereflect::Paragraph)
      expect(paragraph.text_content).to eq('Test content')
    end

    it 'adds an empty paragraph' do
      cell = described_class.create
      paragraph = cell.add_paragraph

      expect(cell.paragraphs.size).to eq(1)
      expect(paragraph).to be_a(Prosereflect::Paragraph)
      expect(paragraph.text_content).to eq('')
    end
  end

  describe 'serialization' do
    it 'converts to hash representation' do
      cell = described_class.create
      cell.add_paragraph('Test content')

      hash = cell.to_h
      expect(hash['type']).to eq('table_cell')
      expect(hash['content'].size).to eq(1)
      expect(hash['content'][0]['type']).to eq('paragraph')
    end
  end
end
