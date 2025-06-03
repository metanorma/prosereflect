# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Prosereflect::Parser do
  let(:fixtures_path) { File.join(__dir__, '..', 'fixtures') }

  describe 'document parsing' do
    describe '.parse_document' do
      it 'parses a simple document' do
        data = {
          'type' => 'doc',
          'content' => [
            {
              'type' => 'paragraph',
              'content' => [
                { 'type' => 'text', 'text' => 'Hello world' }
              ]
            }
          ]
        }

        document = described_class.parse_document(data)
        expect(document).to be_a(Prosereflect::Document)
        expect(document.text_content).to eq('Hello world')
      end

      it 'parses a complex document with multiple blocks' do
        data = {
          'type' => 'doc',
          'content' => [
            {
              'type' => 'paragraph',
              'content' => [
                { 'type' => 'text', 'text' => 'First paragraph' }
              ]
            },
            {
              'type' => 'bullet_list',
              'content' => [
                {
                  'type' => 'list_item',
                  'content' => [
                    {
                      'type' => 'paragraph',
                      'content' => [
                        { 'type' => 'text', 'text' => 'List item' }
                      ]
                    }
                  ]
                }
              ]
            },
            {
              'type' => 'blockquote',
              'content' => [
                {
                  'type' => 'paragraph',
                  'content' => [
                    { 'type' => 'text', 'text' => 'Quote text' }
                  ]
                }
              ]
            }
          ]
        }

        document = described_class.parse_document(data)
        expect(document).to be_a(Prosereflect::Document)
        expect(document.content.size).to eq(3)
        expect(document.content[0]).to be_a(Prosereflect::Paragraph)
        expect(document.content[1]).to be_a(Prosereflect::BulletList)
        expect(document.content[2]).to be_a(Prosereflect::Blockquote)
      end

      context 'with fixtures' do
        it 'parses all YAML fixtures successfully' do
          Dir.glob(File.join(fixtures_path, '*/*.yaml')).each do |yaml_file|
            data = YAML.safe_load(File.read(yaml_file))
            document = described_class.parse_document(data)
            expect(document).to be_a(Prosereflect::Document)
          end
        end

        it 'parses all JSON fixtures successfully' do
          Dir.glob(File.join(fixtures_path, '*/*.json')).each do |json_file|
            data = JSON.parse(File.read(json_file))
            document = described_class.parse_document(data)
            expect(document).to be_a(Prosereflect::Document)
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

        it 'wraps non-document nodes in a document' do
          data = { 'type' => 'paragraph', 'content' => [] }
          document = described_class.parse_document(data)
          expect(document).to be_a(Prosereflect::Document)
          expect(document.content.first).to be_a(Prosereflect::Paragraph)
        end

        it 'wraps generic nodes in a document' do
          document = described_class.parse_document({ 'content' => [] })
          expect(document).to be_a(Prosereflect::Document)
          expect(document.content.size).to eq(1)
          expect(document.content.first).to be_a(Prosereflect::Node)
          expect(document.content.first.type).to eq('node')
        end
      end
    end
  end

  describe 'node parsing' do
    describe '.parse_node' do
      context 'basic nodes' do
        it 'parses text nodes' do
          data = {
            'type' => 'text',
            'text' => 'Hello world',
            'marks' => [
              { 'type' => 'bold' },
              { 'type' => 'italic' }
            ]
          }

          node = described_class.parse_node(data)
          expect(node).to be_a(Prosereflect::Text)
          expect(node.text).to eq('Hello world')
          expect(node.marks.map { |m| m['type'] }).to eq(%w[bold italic])
        end

        it 'parses paragraph nodes' do
          data = {
            'type' => 'paragraph',
            'content' => [
              { 'type' => 'text', 'text' => 'First' },
              { 'type' => 'hard_break' },
              { 'type' => 'text', 'text' => 'Second' }
            ]
          }

          node = described_class.parse_node(data)
          expect(node).to be_a(Prosereflect::Paragraph)
          expect(node.content.size).to eq(3)
          expect(node.text_content).to eq("First\nSecond")
        end

        it 'parses hard break nodes' do
          data = { 'type' => 'hard_break' }
          node = described_class.parse_node(data)
          expect(node).to be_a(Prosereflect::HardBreak)
        end

        it 'parses horizontal rule nodes' do
          data = {
            'type' => 'horizontal_rule',
            'attrs' => {
              'border_style' => 'dashed',
              'width' => '80%'
            }
          }

          node = described_class.parse_node(data)
          expect(node).to be_a(Prosereflect::HorizontalRule)
          expect(node.style).to eq('dashed')
          expect(node.width).to eq('80%')
        end
      end

      context 'list nodes' do
        it 'parses bullet lists' do
          data = {
            'type' => 'bullet_list',
            'attrs' => { 'bullet_style' => 'square' },
            'content' => [
              {
                'type' => 'list_item',
                'content' => [
                  {
                    'type' => 'paragraph',
                    'content' => [{ 'type' => 'text', 'text' => 'Item 1' }]
                  }
                ]
              }
            ]
          }

          node = described_class.parse_node(data)
          expect(node).to be_a(Prosereflect::BulletList)
          expect(node.bullet_style).to eq('square')
          expect(node.items.first.text_content).to eq('Item 1')
        end

        it 'parses ordered lists' do
          data = {
            'type' => 'ordered_list',
            'attrs' => { 'start' => 3 },
            'content' => [
              {
                'type' => 'list_item',
                'content' => [
                  {
                    'type' => 'paragraph',
                    'content' => [{ 'type' => 'text', 'text' => 'Item 3' }]
                  }
                ]
              }
            ]
          }

          node = described_class.parse_node(data)
          expect(node).to be_a(Prosereflect::OrderedList)
          expect(node.start).to eq(3)
          expect(node.items.first.text_content).to eq('Item 3')
        end

        it 'parses nested lists' do
          data = {
            'type' => 'bullet_list',
            'content' => [
              {
                'type' => 'list_item',
                'content' => [
                  {
                    'type' => 'paragraph',
                    'content' => [{ 'type' => 'text', 'text' => 'Level 1' }]
                  },
                  {
                    'type' => 'ordered_list',
                    'content' => [
                      {
                        'type' => 'list_item',
                        'content' => [
                          {
                            'type' => 'paragraph',
                            'content' => [{ 'type' => 'text', 'text' => 'Level 2' }]
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
          expect(node.items.first.content.size).to eq(2)
          expect(node.items.first.content[1]).to be_a(Prosereflect::OrderedList)
        end
      end

      context 'table nodes' do
        it 'parses tables with complex content' do
          data = {
            'type' => 'table',
            'content' => [
              {
                'type' => 'table_row',
                'content' => [
                  {
                    'type' => 'table_cell',
                    'attrs' => { 'colspan' => 2 },
                    'content' => [
                      {
                        'type' => 'paragraph',
                        'content' => [
                          {
                            'type' => 'text',
                            'text' => 'Header',
                            'marks' => [{ 'type' => 'bold' }]
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
          expect(node).to be_a(Prosereflect::Table)
          expect(node.rows.first.cells.first.attrs['colspan']).to eq(2)
          expect(node.rows.first.cells.first.text_content).to eq('Header')
        end
      end

      context 'blockquote nodes' do
        it 'parses blockquotes with citation' do
          data = {
            'type' => 'blockquote',
            'attrs' => { 'cite' => 'Author' },
            'content' => [
              {
                'type' => 'paragraph',
                'content' => [{ 'type' => 'text', 'text' => 'Quote' }]
              }
            ]
          }

          node = described_class.parse_node(data)
          expect(node).to be_a(Prosereflect::Blockquote)
          expect(node.citation).to eq('Author')
          expect(node.text_content).to eq('Quote')
        end
      end

      context 'with invalid input' do
        it 'returns generic node for unknown types' do
          data = { 'type' => 'unknown_type' }
          node = described_class.parse_node(data)
          expect(node).to be_a(Prosereflect::Node)
          expect(node.type).to eq('node')
        end

        it 'handles missing content gracefully' do
          data = { 'type' => 'paragraph' }
          node = described_class.parse_node(data)
          expect(node).to be_a(Prosereflect::Paragraph)
          expect(node.content).to eq([])
        end

        it 'handles missing attributes gracefully' do
          data = { 'type' => 'table_cell' }
          node = described_class.parse_node(data)
          expect(node).to be_a(Prosereflect::TableCell)
          expect(node.attrs).to be_nil
        end
      end
    end
  end
end
