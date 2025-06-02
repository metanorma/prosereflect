# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Prosereflect::Parser do
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
            expect(document).to be_a(Prosereflect::Document)
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
            expect(document).to be_a(Prosereflect::Document)
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
      expect(described_class.parse_node(doc_data)).to be_a(Prosereflect::Document)

      # Test paragraph node
      para_data = { 'type' => 'paragraph', 'content' => [] }
      expect(described_class.parse_node(para_data)).to be_a(Prosereflect::Paragraph)

      # Test text node
      text_data = { 'type' => 'text', 'text' => 'Hello' }
      expect(described_class.parse_node(text_data)).to be_a(Prosereflect::Text)

      # Test hard_break node
      break_data = { 'type' => 'hard_break' }
      expect(described_class.parse_node(break_data)).to be_a(Prosereflect::HardBreak)

      # Test table node
      table_data = { 'type' => 'table', 'content' => [] }
      expect(described_class.parse_node(table_data)).to be_a(Prosereflect::Table)

      # Test table_row node
      row_data = { 'type' => 'table_row', 'content' => [] }
      expect(described_class.parse_node(row_data)).to be_a(Prosereflect::TableRow)

      # Test table_cell node
      cell_data = { 'type' => 'table_cell', 'content' => [] }
      expect(described_class.parse_node(cell_data)).to be_a(Prosereflect::TableCell)

      # Test ordered list node
      ordered_list_data = { 'type' => 'ordered_list', 'content' => [] }
      expect(described_class.parse_node(ordered_list_data)).to be_a(Prosereflect::OrderedList)

      # Test bullet list node
      bullet_list_data = { 'type' => 'bullet_list', 'content' => [] }
      expect(described_class.parse_node(bullet_list_data)).to be_a(Prosereflect::BulletList)

      # Test list item node
      list_item_data = { 'type' => 'list_item', 'content' => [] }
      expect(described_class.parse_node(list_item_data)).to be_a(Prosereflect::ListItem)

      # Test blockquote node
      blockquote_data = { 'type' => 'blockquote', 'content' => [] }
      expect(described_class.parse_node(blockquote_data)).to be_a(Prosereflect::Blockquote)

      # Test horizontal rule node
      hr_data = { 'type' => 'horizontal_rule' }
      expect(described_class.parse_node(hr_data)).to be_a(Prosereflect::HorizontalRule)

      # Test generic node
      generic_data = { 'type' => 'unknown_type' }
      expect(described_class.parse_node(generic_data)).to be_a(Prosereflect::Node)
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
      expect(node).to be_a(Prosereflect::Paragraph)
      expect(node.content.size).to eq(3)
      expect(node.content[0]).to be_a(Prosereflect::Text)
      expect(node.content[1]).to be_a(Prosereflect::HardBreak)
      expect(node.content[2]).to be_a(Prosereflect::Text)
    end

    it 'handles nodes with marks' do
      data = {
        'type' => 'text',
        'text' => 'Bold text',
        'marks' => [{ 'type' => 'bold' }]
      }

      node = described_class.parse_node(data)
      expect(node).to be_a(Prosereflect::Text)
      expect(node.marks).to eq([{ 'type' => 'bold' }])
    end

    it 'handles nodes with attributes' do
      data = {
        'type' => 'table_cell',
        'attrs' => { 'colspan' => 2, 'rowspan' => 1 },
        'content' => []
      }

      node = described_class.parse_node(data)
      expect(node).to be_a(Prosereflect::TableCell)
      expect(node.attrs).to eq({ 'colspan' => 2, 'rowspan' => 1 })
    end

    it 'handles ordered lists with start attribute' do
      data = {
        'type' => 'ordered_list',
        'attrs' => { 'start' => 3 },
        'content' => [
          {
            'type' => 'list_item',
            'content' => [
              {
                'type' => 'paragraph',
                'content' => [{ 'type' => 'text', 'text' => 'Third item' }]
              }
            ]
          }
        ]
      }

      node = described_class.parse_node(data)
      expect(node).to be_a(Prosereflect::OrderedList)
      expect(node.start).to eq(3)
      expect(node.items.first).to be_a(Prosereflect::ListItem)
      expect(node.items.first.text_content).to eq('Third item')
    end

    it 'handles bullet lists with style attribute' do
      data = {
        'type' => 'bullet_list',
        'attrs' => { 'bullet_style' => 'square' },
        'content' => [
          {
            'type' => 'list_item',
            'content' => [
              {
                'type' => 'paragraph',
                'content' => [{ 'type' => 'text', 'text' => 'Square bullet' }]
              }
            ]
          }
        ]
      }

      node = described_class.parse_node(data)
      expect(node).to be_a(Prosereflect::BulletList)
      expect(node.bullet_style).to eq('square')
      expect(node.items.first).to be_a(Prosereflect::ListItem)
      expect(node.items.first.text_content).to eq('Square bullet')
    end

    it 'handles blockquotes with citation' do
      data = {
        'type' => 'blockquote',
        'attrs' => { 'cite' => 'Author Name' },
        'content' => [
          {
            'type' => 'paragraph',
            'content' => [{ 'type' => 'text', 'text' => 'Quote text' }]
          }
        ]
      }

      node = described_class.parse_node(data)
      expect(node).to be_a(Prosereflect::Blockquote)
      expect(node.citation).to eq('Author Name')
      expect(node.blocks.first).to be_a(Prosereflect::Paragraph)
      expect(node.blocks.first.text_content).to eq('Quote text')
    end

    it 'handles horizontal rules with style attributes' do
      data = {
        'type' => 'horizontal_rule',
        'attrs' => {
          'border_style' => 'dashed',
          'width' => '80%',
          'thickness' => 2
        }
      }

      node = described_class.parse_node(data)
      expect(node).to be_a(Prosereflect::HorizontalRule)
      expect(node.style).to eq('dashed')
      expect(node.width).to eq('80%')
      expect(node.thickness).to eq(2)
    end

    it 'handles nested lists' do
      data = {
        'type' => 'bullet_list',
        'content' => [
          {
            'type' => 'list_item',
            'content' => [
              {
                'type' => 'paragraph',
                'content' => [{ 'type' => 'text', 'text' => 'First level' }]
              },
              {
                'type' => 'ordered_list',
                'attrs' => { 'start' => 1 },
                'content' => [
                  {
                    'type' => 'list_item',
                    'content' => [
                      {
                        'type' => 'paragraph',
                        'content' => [{ 'type' => 'text', 'text' => 'Nested item' }]
                      }
                    ]
                  }
                ]
              }
            ]
          }
        ]
      }

      node = described_class.parse_node(data)
      expect(node).to be_a(Prosereflect::BulletList)

      first_item = node.items.first
      expect(first_item.content.size).to eq(2) # paragraph and nested list
      expect(first_item.content.first).to be_a(Prosereflect::Paragraph)
      expect(first_item.content.last).to be_a(Prosereflect::OrderedList)

      nested_list = first_item.content.last
      expect(nested_list.start).to eq(1)
      expect(nested_list.items.first.text_content).to eq('Nested item')
    end
  end
end
