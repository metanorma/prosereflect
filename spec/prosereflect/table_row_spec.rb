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

      expected = {
        'type' => 'table_row',
        'content' => []
      }

      expect(row.to_h).to eq(expected)
    end

    it 'creates a table row with attributes' do
      row = described_class.create(attrs: {
                                     'background' => '#f5f5f5',
                                     'height' => '40px',
                                     'alignment' => 'center'
                                   })

      expected = {
        'type' => 'table_row',
        'attrs' => {
          'background' => '#f5f5f5',
          'height' => '40px',
          'alignment' => 'center'
        },
        'content' => []
      }

      expect(row.to_h).to eq(expected)
    end
  end

  describe 'row structure' do
    it 'creates a row with simple text cells' do
      row = described_class.create
      row.add_cell('First')
      row.add_cell('Second')
      row.add_cell('Third')

      expected = {
        'type' => 'table_row',
        'content' => [{
          'type' => 'table_cell',
          'content' => [{
            'type' => 'paragraph',
            'content' => [{
              'type' => 'text',
              'text' => 'First'
            }]
          }]
        }, {
          'type' => 'table_cell',
          'content' => [{
            'type' => 'paragraph',
            'content' => [{
              'type' => 'text',
              'text' => 'Second'
            }]
          }]
        }, {
          'type' => 'table_cell',
          'content' => [{
            'type' => 'paragraph',
            'content' => [{
              'type' => 'text',
              'text' => 'Third'
            }]
          }]
        }]
      }

      expect(row.to_h).to eq(expected)
    end

    it 'creates a row with complex cell content' do
      row = described_class.create

      # First cell with multiple paragraphs
      cell = row.add_cell
      para = cell.add_paragraph('Main point:')
      para.add_hard_break
      para.add_text('Important', [Prosereflect::Mark::Bold.new])
      cell.add_paragraph('(details below)')

      # Second cell with mixed formatting
      cell = row.add_cell
      para = cell.add_paragraph
      para.add_text('Status: ', [Prosereflect::Mark::Bold.new])
      para.add_text('In Progress', [Prosereflect::Mark::Italic.new])
      para.add_hard_break
      para.add_text('Updated', [Prosereflect::Mark::Strike.new])

      expected = {
        'type' => 'table_row',
        'content' => [{
          'type' => 'table_cell',
          'content' => [{
            'type' => 'paragraph',
            'content' => [{
              'type' => 'text',
              'text' => 'Main point:'
            }, {
              'type' => 'hard_break'
            }, {
              'type' => 'text',
              'text' => 'Important',
              'marks' => [{
                'type' => 'bold'
              }]
            }]
          }, {
            'type' => 'paragraph',
            'content' => [{
              'type' => 'text',
              'text' => '(details below)'
            }]
          }]
        }, {
          'type' => 'table_cell',
          'content' => [{
            'type' => 'paragraph',
            'content' => [{
              'type' => 'text',
              'text' => 'Status: ',
              'marks' => [{
                'type' => 'bold'
              }]
            }, {
              'type' => 'text',
              'text' => 'In Progress',
              'marks' => [{
                'type' => 'italic'
              }]
            }, {
              'type' => 'hard_break'
            }, {
              'type' => 'text',
              'text' => 'Updated',
              'marks' => [{
                'type' => 'strike'
              }]
            }]
          }]
        }]
      }

      expect(row.to_h).to eq(expected)
    end
  end

  describe 'row operations' do
    let(:row) do
      r = described_class.create
      r.add_cell('First')
      r.add_cell('Second')
      r.add_cell('Third')
      r
    end

    describe '#cells' do
      it 'returns all cells in the row' do
        expect(row.cells.size).to eq(3)
        expect(row.cells).to all(be_a(Prosereflect::TableCell))
        expect(row.cells.map(&:text_content)).to eq(%w[First Second Third])
      end

      it 'returns empty array for row with no cells' do
        empty_row = described_class.create
        expect(empty_row.cells).to eq([])
      end
    end

    describe '#add_cell' do
      it 'adds a cell with text content and attributes' do
        cell = row.add_cell('Test', attrs: {
                              'colspan' => 2,
                              'rowspan' => 1,
                              'background' => '#eee'
                            })

        expected = {
          'type' => 'table_cell',
          'attrs' => {
            'colspan' => 2,
            'rowspan' => 1,
            'background' => '#eee'
          },
          'content' => [{
            'type' => 'paragraph',
            'content' => [{
              'type' => 'text',
              'text' => 'Test'
            }]
          }]
        }

        expect(cell.to_h).to eq(expected)
      end

      it 'adds a cell with formatted content' do
        cell = row.add_cell
        para = cell.add_paragraph
        para.add_text('Bold', [Prosereflect::Mark::Bold.new])
        para.add_text(' and ')
        para.add_text('italic', [Prosereflect::Mark::Italic.new])

        expected = {
          'type' => 'table_cell',
          'content' => [{
            'type' => 'paragraph',
            'content' => [{
              'type' => 'text',
              'text' => 'Bold',
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
            }]
          }]
        }

        expect(cell.to_h).to eq(expected)
      end
    end
  end
end
