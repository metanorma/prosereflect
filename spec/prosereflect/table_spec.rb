# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Prosereflect::Table do
  describe 'initialization' do
    it 'initializes as a table node' do
      table = described_class.new({ 'type' => 'table' })
      expect(table.type).to eq('table')
    end
  end

  describe '.create' do
    it 'creates an empty table' do
      table = described_class.create
      expect(table).to be_a(described_class)
      expect(table.type).to eq('table')
      expect(table.content).to be_empty
    end

    it 'creates a table with attributes' do
      attrs = { 'width' => '100%' }
      table = described_class.new(attrs: attrs)
      expect(table.attrs).to eq(attrs)
    end
  end

  describe 'row access methods' do
    let(:table) do
      t = described_class.create
      t.add_header(['Header 1', 'Header 2'])
      t.add_row(['Data 1', 'Data 2'])
      t.add_row(['Data 3', 'Data 4'])
      t
    end

    describe '#rows' do
      it 'returns all rows' do
        expect(table.rows.size).to eq(3)
        expect(table.rows).to all(be_a(Prosereflect::TableRow))
      end
    end

    describe '#header_row' do
      it 'returns the first row' do
        expect(table.header_row).to be_a(Prosereflect::TableRow)
        expect(table.header_row.cells.first.text_content).to eq('Header 1')
      end
    end

    describe '#data_rows' do
      it 'returns all rows except the header' do
        expect(table.data_rows.size).to eq(2)
        expect(table.data_rows).to all(be_a(Prosereflect::TableRow))
        expect(table.data_rows.first.cells.first.text_content).to eq('Data 1')
      end

      it 'returns empty array if there are no data rows' do
        table = described_class.create
        table.add_header(['Header'])
        expect(table.data_rows).to eq([])
      end
    end

    describe '#cell_at' do
      it 'returns cell at specified position' do
        cell = table.cell_at(0, 1)
        expect(cell).to be_a(Prosereflect::TableCell)
        expect(cell.text_content).to eq('Data 2')
      end

      it 'returns nil for out of bounds indices' do
        expect(table.cell_at(-1, 0)).to be_nil
        expect(table.cell_at(0, -1)).to be_nil
        expect(table.cell_at(5, 0)).to be_nil
        expect(table.cell_at(0, 5)).to be_nil
      end
    end
  end

  describe 'table building methods' do
    describe '#add_header' do
      it 'adds a header row with cells' do
        table = described_class.create
        header = table.add_header(['Col 1', 'Col 2'])

        expect(table.rows.size).to eq(1)
        expect(header).to be_a(Prosereflect::TableRow)
        expect(header.cells.size).to eq(2)
        expect(header.cells.map(&:text_content)).to eq(['Col 1', 'Col 2'])
      end
    end

    describe '#add_row' do
      it 'adds a row with cells' do
        table = described_class.create
        row = table.add_row(['Data 1', 'Data 2'])

        expect(table.rows.size).to eq(1)
        expect(row).to be_a(Prosereflect::TableRow)
        expect(row.cells.size).to eq(2)
        expect(row.cells.map(&:text_content)).to eq(['Data 1', 'Data 2'])
      end

      it 'adds an empty row when no data provided' do
        table = described_class.create
        row = table.add_row

        expect(table.rows.size).to eq(1)
        expect(row.cells).to be_empty
      end
    end

    describe '#add_rows' do
      it 'adds multiple rows at once' do
        table = described_class.create
        table.add_rows([
                         ['Row 1, Cell 1', 'Row 1, Cell 2'],
                         ['Row 2, Cell 1', 'Row 2, Cell 2']
                       ])

        expect(table.rows.size).to eq(2)
        expect(table.rows[0].cells.size).to eq(2)
        expect(table.rows[1].cells.size).to eq(2)
        expect(table.rows[0].cells.first.text_content).to eq('Row 1, Cell 1')
        expect(table.rows[1].cells.first.text_content).to eq('Row 2, Cell 1')
      end
    end
  end

  describe 'serialization' do
    it 'converts to hash representation' do
      table = described_class.create
      table.add_header(['Col 1', 'Col 2'])
      table.add_row(['Data 1', 'Data 2'])

      hash = table.to_h
      expect(hash['type']).to eq('table')
      expect(hash['content'].size).to eq(2)
      expect(hash['content'][0]['type']).to eq('table_row')
      expect(hash['content'][1]['type']).to eq('table_row')
    end
  end
end
