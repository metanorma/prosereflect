# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Prosemirror::Parser do
  let(:fixtures_path) { File.join(__dir__, '..', 'fixtures') }

  describe '.parse_document' do
    context 'with YAML fixtures' do
      let(:yaml_files) { Dir.glob(File.join(fixtures_path, '*/*.yaml')) }

      it 'parses all YAML fixtures successfully' do
        yaml_files.each do |yaml_file|
          yaml_content = File.read(yaml_file)
          data = YAML.safe_load(yaml_content)

          expect do
            document = described_class.parse_document(data)
            expect(document).to be_a(Prosemirror::Document)
          end.not_to raise_error
        end
      end
    end

    context 'with JSON fixtures' do
      let(:json_files) { Dir.glob(File.join(fixtures_path, '*/*.json')) }

      it 'parses all JSON fixtures successfully' do
        json_files.each do |json_file|
          json_content = File.read(json_file)
          data = JSON.parse(json_content)

          expect do
            document = described_class.parse_document(data)
            expect(document).to be_a(Prosemirror::Document)
          end.not_to raise_error
        end
      end
    end

    context 'with invalid input' do
      it 'raises an error for nil input' do
        expect { described_class.parse_document(nil) }.to raise_error(ArgumentError)
      end

      it 'raises an error for non-hash input' do
        expect { described_class.parse_document('not a hash') }.to raise_error(ArgumentError)
      end
    end
  end

  describe '.parse_node' do
    it 'creates the correct node type based on the input' do
      # Test document node
      doc_data = { 'type' => 'doc', 'content' => [] }
      expect(described_class.parse_node(doc_data)).to be_a(Prosemirror::Document)

      # Test paragraph node
      para_data = { 'type' => 'paragraph', 'content' => [] }
      expect(described_class.parse_node(para_data)).to be_a(Prosemirror::Paragraph)

      # Test text node
      text_data = { 'type' => 'text', 'text' => 'Hello' }
      expect(described_class.parse_node(text_data)).to be_a(Prosemirror::Text)

      # Test hard_break node
      break_data = { 'type' => 'hard_break' }
      expect(described_class.parse_node(break_data)).to be_a(Prosemirror::HardBreak)

      # Test table node
      table_data = { 'type' => 'table', 'content' => [] }
      expect(described_class.parse_node(table_data)).to be_a(Prosemirror::Table)

      # Test table_row node
      row_data = { 'type' => 'table_row', 'content' => [] }
      expect(described_class.parse_node(row_data)).to be_a(Prosemirror::TableRow)

      # Test table_cell node
      cell_data = { 'type' => 'table_cell', 'content' => [] }
      expect(described_class.parse_node(cell_data)).to be_a(Prosemirror::TableCell)

      # Test generic node
      generic_data = { 'type' => 'unknown_type' }
      expect(described_class.parse_node(generic_data)).to be_a(Prosemirror::Node)
    end

    it 'handles nodes with content' do
      data = {
        'type' => 'paragraph',
        'content' => [
          { 'type' => 'text', 'text' => 'Hello' },
          { 'type' => 'hard_break' },
          { 'type' => 'text', 'text' => 'World' }
        ]
      }

      node = described_class.parse_node(data)
      expect(node).to be_a(Prosemirror::Paragraph)
      expect(node.content.size).to eq(3)
      expect(node.content[0]).to be_a(Prosemirror::Text)
      expect(node.content[1]).to be_a(Prosemirror::HardBreak)
      expect(node.content[2]).to be_a(Prosemirror::Text)
    end

    it 'handles nodes with marks' do
      data = {
        'type' => 'text',
        'text' => 'Bold text',
        'marks' => [{ 'type' => 'bold' }]
      }

      node = described_class.parse_node(data)
      expect(node).to be_a(Prosemirror::Text)
      expect(node.marks).to eq([{ 'type' => 'bold' }])
    end

    it 'handles nodes with attributes' do
      data = {
        'type' => 'table_cell',
        'attrs' => { 'colspan' => 2, 'rowspan' => 1 },
        'content' => []
      }

      node = described_class.parse_node(data)
      expect(node).to be_a(Prosemirror::TableCell)
      expect(node.attrs).to eq({ 'colspan' => 2, 'rowspan' => 1 })
    end
  end
end
