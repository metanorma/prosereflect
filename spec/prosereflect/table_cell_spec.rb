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

      expected = {
        'type' => 'table_cell',
        'content' => []
      }

      expect(cell.to_h).to eq(expected)
    end

    it 'creates a table cell with attributes' do
      cell = described_class.create(attrs: {
                                      'colspan' => 2,
                                      'rowspan' => 1,
                                      'background' => '#f5f5f5',
                                      'align' => 'center',
                                      'valign' => 'middle'
                                    })

      expected = {
        'type' => 'table_cell',
        'attrs' => {
          'colspan' => 2,
          'rowspan' => 1,
          'background' => '#f5f5f5',
          'align' => 'center',
          'valign' => 'middle'
        },
        'content' => []
      }

      expect(cell.to_h).to eq(expected)
    end
  end

  describe 'cell structure' do
    it 'creates a cell with simple text content' do
      cell = described_class.create
      cell.add_paragraph('Simple text')

      expected = {
        'type' => 'table_cell',
        'content' => [{
          'type' => 'paragraph',
          'content' => [{
            'type' => 'text',
            'text' => 'Simple text'
          }]
        }]
      }

      expect(cell.to_h).to eq(expected)
    end

    it 'creates a cell with complex content' do
      cell = described_class.create

      # First paragraph with mixed formatting
      para = cell.add_paragraph('This is ')
      para.add_text('bold', [Prosereflect::Mark::Bold.new])
      para.add_text(' and ')
      para.add_text('italic', [Prosereflect::Mark::Italic.new])
      para.add_hard_break
      para.add_text('with a line break')

      # Second paragraph with more formatting
      para = cell.add_paragraph
      para.add_text('Status: ', [Prosereflect::Mark::Bold.new])
      para.add_text('Done', [Prosereflect::Mark::Strike.new])
      para.add_text(' → ')
      para.add_text('In Progress', [Prosereflect::Mark::Italic.new])

      expected = {
        'type' => 'table_cell',
        'content' => [{
          'type' => 'paragraph',
          'content' => [{
            'type' => 'text',
            'text' => 'This is '
          }, {
            'type' => 'text',
            'text' => 'bold',
            'marks' => [{
              'type' => 'bold'
            }]
          }, {
            'type' => 'text',
            'text' => ' and '
          }, {
            'type' => 'text',
            'text' => 'italic',
            'marks' => [{
              'type' => 'italic'
            }]
          }, {
            'type' => 'hard_break'
          }, {
            'type' => 'text',
            'text' => 'with a line break'
          }]
        }, {
          'type' => 'paragraph',
          'content' => [{
            'type' => 'text',
            'text' => 'Status: ',
            'marks' => [{
              'type' => 'bold'
            }]
          }, {
            'type' => 'text',
            'text' => 'Done',
            'marks' => [{
              'type' => 'strike'
            }]
          }, {
            'type' => 'text',
            'text' => ' → '
          }, {
            'type' => 'text',
            'text' => 'In Progress',
            'marks' => [{
              'type' => 'italic'
            }]
          }]
        }]
      }

      expect(cell.to_h).to eq(expected)
    end
  end

  describe 'cell operations' do
    let(:cell) do
      c = described_class.create
      c.add_paragraph('First paragraph')
      c.add_paragraph('Second paragraph')
      c.add_paragraph('Third paragraph')
      c
    end

    describe '#paragraphs' do
      it 'returns all paragraphs in the cell' do
        expect(cell.paragraphs.size).to eq(3)
        expect(cell.paragraphs).to all(be_a(Prosereflect::Paragraph))
        expect(cell.paragraphs.map(&:text_content)).to eq([
                                                            'First paragraph',
                                                            'Second paragraph',
                                                            'Third paragraph'
                                                          ])
      end

      it 'returns empty array for cell with no paragraphs' do
        empty_cell = described_class.create
        expect(empty_cell.paragraphs).to eq([])
      end
    end

    describe '#text_content' do
      it 'returns concatenated text from all paragraphs with newlines' do
        expect(cell.text_content).to eq("First paragraph\nSecond paragraph\nThird paragraph")
      end

      it 'returns empty string for empty cell' do
        empty_cell = described_class.create
        expect(empty_cell.text_content).to eq('')
      end

      it 'handles complex formatting and line breaks' do
        cell = described_class.create
        para = cell.add_paragraph('Line 1')
        para.add_hard_break
        para.add_text('Line 2', [Prosereflect::Mark::Bold.new])
        para.add_hard_break
        para.add_text('Line 3', [Prosereflect::Mark::Italic.new])

        expect(cell.text_content).to eq("Line 1\nLine 2\nLine 3")
      end
    end

    describe '#lines' do
      it 'splits text content into lines' do
        expect(cell.lines).to eq([
                                   'First paragraph',
                                   'Second paragraph',
                                   'Third paragraph'
                                 ])
      end

      it 'returns empty array for empty cell' do
        empty_cell = described_class.create
        expect(empty_cell.lines).to eq([])
      end

      it 'handles hard breaks within paragraphs' do
        cell = described_class.create
        para = cell.add_paragraph('First line')
        para.add_hard_break
        para.add_text('Second line')
        cell.add_paragraph('Third line')

        expect(cell.lines).to eq([
                                   'First line',
                                   'Second line',
                                   'Third line'
                                 ])
      end
    end

    describe '#add_paragraph' do
      it 'adds a paragraph with text and formatting' do
        cell = described_class.create
        para = cell.add_paragraph('Main text')
        para.add_text(' (', [Prosereflect::Mark::Bold.new])
        para.add_text('important', [Prosereflect::Mark::Bold.new, Prosereflect::Mark::Italic.new])
        para.add_text(')', [Prosereflect::Mark::Bold.new])

        expected = {
          'type' => 'table_cell',
          'content' => [{
            'type' => 'paragraph',
            'content' => [{
              'type' => 'text',
              'text' => 'Main text'
            }, {
              'type' => 'text',
              'text' => ' (',
              'marks' => [{
                'type' => 'bold'
              }]
            }, {
              'type' => 'text',
              'text' => 'important',
              'marks' => [{
                'type' => 'bold'
              }, {
                'type' => 'italic'
              }]
            }, {
              'type' => 'text',
              'text' => ')',
              'marks' => [{
                'type' => 'bold'
              }]
            }]
          }]
        }

        expect(cell.to_h).to eq(expected)
      end

      it 'adds multiple paragraphs with mixed content' do
        cell = described_class.create

        # First paragraph with hard break
        para = cell.add_paragraph('Title')
        para.add_hard_break
        para.add_text('Subtitle', [Prosereflect::Mark::Italic.new])

        # Second paragraph with mixed formatting
        para = cell.add_paragraph
        para.add_text('Note: ', [Prosereflect::Mark::Bold.new])
        para.add_text('This is important')

        expected = {
          'type' => 'table_cell',
          'content' => [{
            'type' => 'paragraph',
            'content' => [{
              'type' => 'text',
              'text' => 'Title'
            }, {
              'type' => 'hard_break'
            }, {
              'type' => 'text',
              'text' => 'Subtitle',
              'marks' => [{
                'type' => 'italic'
              }]
            }]
          }, {
            'type' => 'paragraph',
            'content' => [{
              'type' => 'text',
              'text' => 'Note: ',
              'marks' => [{
                'type' => 'bold'
              }]
            }, {
              'type' => 'text',
              'text' => 'This is important'
            }]
          }]
        }

        expect(cell.to_h).to eq(expected)
      end
    end
  end

  describe 'serialization' do
    it 'converts to hash representation' do
      cell = described_class.new
      cell.add_paragraph('Test content')

      hash = cell.to_h
      expect(hash['type']).to eq('table_cell')
      expect(hash['content'].size).to eq(1)
      expect(hash['content'][0]['type']).to eq('paragraph')
    end
  end
end
