# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Prosereflect::TableRow do
  describe 'initialization' do
    it 'initializes as a table_row node' do
      row = described_class.new({ 'type' => 'table_row' })
      expect(row.type).to eq('table_row')
    end
  end

  describe '.create' do
    it 'creates an empty table row' do
      row = described_class.create
      expect(row).to be_a(described_class)
      expect(row.type).to eq('table_row')
      expect(row.content).to be_empty
    end

    it 'creates a table row with attributes' do
      attrs = { 'background' => '#f5f5f5' }
      row = described_class.create(attrs)
      expect(row.attrs).to eq(attrs)
    end
  end

  describe '#cells' do
    it 'returns all cells in the row' do
      row = described_class.create
      row.add_cell('Cell 1')
      row.add_cell('Cell 2')

      expect(row.cells.size).to eq(2)
      expect(row.cells).to all(be_a(Prosereflect::TableCell))
    end

    it 'returns empty array for row with no cells' do
      row = described_class.create
      expect(row.cells).to eq([])
    end
  end

  describe '#add_cell' do
    it 'adds a cell with text content' do
      row = described_class.create
      cell = row.add_cell('Test content')

      expect(row.cells.size).to eq(1)
      expect(cell).to be_a(Prosereflect::TableCell)
      expect(cell.text_content).to eq('Test content')
    end

    it 'adds an empty cell' do
      row = described_class.create
      cell = row.add_cell

      expect(row.cells.size).to eq(1)
      expect(cell).to be_a(Prosereflect::TableCell)
      expect(cell.text_content).to eq('')
    end
  end

  describe 'serialization' do
    it 'converts to hash representation' do
      row = described_class.create
      row.add_cell('Cell 1')
      row.add_cell('Cell 2')

      hash = row.to_h
      expect(hash['type']).to eq('table_row')
      expect(hash['content'].size).to eq(2)
      expect(hash['content'][0]['type']).to eq('table_cell')
      expect(hash['content'][1]['type']).to eq('table_cell')
    end
  end
end
