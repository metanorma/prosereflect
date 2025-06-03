# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Prosereflect::HardBreak do
  describe 'initialization' do
    it 'initializes as a hard_break node' do
      break_node = described_class.new({ 'type' => 'hard_break' })
      expect(break_node.type).to eq('hard_break')
    end
  end

  describe '.create' do
    it 'creates a simple hard break' do
      break_node = described_class.create

      expected = {
        'type' => 'hard_break'
      }

      expect(break_node.to_h).to eq(expected)
    end

    it 'creates a hard break with a single mark' do
      break_node = described_class.create
      break_node.marks = [{ 'type' => 'bold' }]

      expected = {
        'type' => 'hard_break',
        'marks' => [{
          'type' => 'bold'
        }]
      }

      expect(break_node.to_h).to eq(expected)
    end

    it 'creates a hard break with multiple marks' do
      break_node = described_class.create
      break_node.marks = [
        { 'type' => 'bold' },
        { 'type' => 'italic' },
        { 'type' => 'strike' }
      ]

      expected = {
        'type' => 'hard_break',
        'marks' => [{
          'type' => 'bold'
        }, {
          'type' => 'italic'
        }, {
          'type' => 'strike'
        }]
      }

      expect(break_node.to_h).to eq(expected)
    end
  end

  describe 'in document context' do
    it 'works in a paragraph with mixed content' do
      paragraph = Prosereflect::Paragraph.new
      paragraph.add_text('First line')
      paragraph.add_hard_break
      paragraph.add_text('Second line with ')
      paragraph.add_text('bold', [Prosereflect::Mark::Bold.new])
      paragraph.add_hard_break
      paragraph.add_text('Third line')

      expected = {
        'type' => 'paragraph',
        'content' => [{
          'type' => 'text',
          'text' => 'First line'
        }, {
          'type' => 'hard_break'
        }, {
          'type' => 'text',
          'text' => 'Second line with '
        }, {
          'type' => 'text',
          'text' => 'bold',
          'marks' => [{
            'type' => 'bold'
          }]
        }, {
          'type' => 'hard_break'
        }, {
          'type' => 'text',
          'text' => 'Third line'
        }]
      }

      expect(paragraph.to_h).to eq(expected)
    end

    it 'works in a list item with multiple breaks' do
      list = Prosereflect::BulletList.new
      item = list.add_item('First part')
      item.add_hard_break([{ 'type' => 'strike' }])
      item.add_text('Second part')
      item.add_hard_break
      item.add_text('Third part')

      expected = {
        'type' => 'bullet_list',
        'attrs' => {
          'bullet_style' => nil
        },
        'content' => [{
          'type' => 'list_item',
          'content' => [{
            'type' => 'paragraph',
            'content' => [{
              'type' => 'text',
              'text' => 'First part'
            }, {
              'type' => 'hard_break',
              'marks' => [{
                'type' => 'strike'
              }]
            }, {
              'type' => 'text',
              'text' => 'Second part'
            }, {
              'type' => 'hard_break'
            }, {
              'type' => 'text',
              'text' => 'Third part'
            }]
          }]
        }]
      }

      expect(list.to_h).to eq(expected)
    end

    it 'works in a table cell with multiple paragraphs' do
      cell = Prosereflect::TableCell.new
      para1 = cell.add_paragraph('First paragraph')
      para1.add_hard_break
      para1.add_text('continues here')

      para2 = cell.add_paragraph('Second paragraph')
      para2.add_hard_break([Prosereflect::Mark::Italic.new])
      para2.add_text('with style')

      expected = {
        'type' => 'table_cell',
        'content' => [{
          'type' => 'paragraph',
          'content' => [{
            'type' => 'text',
            'text' => 'First paragraph'
          }, {
            'type' => 'hard_break'
          }, {
            'type' => 'text',
            'text' => 'continues here'
          }]
        }, {
          'type' => 'paragraph',
          'content' => [{
            'type' => 'text',
            'text' => 'Second paragraph'
          }, {
            'type' => 'hard_break',
            'marks' => [{
              'type' => 'italic'
            }]
          }, {
            'type' => 'text',
            'text' => 'with style'
          }]
        }]
      }

      expect(cell.to_h).to eq(expected)
    end
  end

  describe '#text_content' do
    it 'returns a newline character' do
      break_node = described_class.new
      expect(break_node.text_content).to eq("\n")
    end

    it 'returns a newline character regardless of marks' do
      break_node = described_class.create(marks: [
                                            Prosereflect::Mark::Bold.new,
                                            Prosereflect::Mark::Italic.new
                                          ])
      expect(break_node.text_content).to eq("\n")
    end

    it 'properly formats text in a paragraph with multiple breaks' do
      paragraph = Prosereflect::Paragraph.new
      paragraph.add_text('Line 1')
      paragraph.add_hard_break
      paragraph.add_text('Line 2')
      paragraph.add_hard_break
      paragraph.add_text('Line 3')

      expect(paragraph.text_content).to eq("Line 1\nLine 2\nLine 3")
    end
  end

  describe 'serialization' do
    it 'preserves mark order in serialization' do
      break_node = described_class.create
      break_node.marks = [
        { 'type' => 'bold' },
        { 'type' => 'italic' },
        { 'type' => 'strike' },
        { 'type' => 'underline' }
      ]

      expected = {
        'type' => 'hard_break',
        'marks' => [{
          'type' => 'bold'
        }, {
          'type' => 'italic'
        }, {
          'type' => 'strike'
        }, {
          'type' => 'underline'
        }]
      }

      expect(break_node.to_h).to eq(expected)
    end

    it 'handles empty marks array' do
      break_node = described_class.create
      break_node.marks = []
      expect(break_node.to_h).to eq({ 'type' => 'hard_break' })
    end

    it 'excludes marks when nil' do
      break_node = described_class.create
      break_node.marks = nil
      expect(break_node.to_h).to eq({ 'type' => 'hard_break' })
    end
  end
end
