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

      expected = {
        'type' => 'table',
        'content' => []
      }

      expect(table.to_h).to eq(expected)
    end

    it 'creates a table with attributes' do
      table = described_class.create(attrs: {
                                       'width' => '100%',
                                       'alignment' => 'center',
                                       'border' => '1'
                                     })

      expected = {
        'type' => 'table',
        'attrs' => {
          'width' => '100%',
          'alignment' => 'center',
          'border' => '1'
        },
        'content' => []
      }

      expect(table.to_h).to eq(expected)
    end
  end

  describe 'table structure' do
    it 'creates a simple table with header and data' do
      table = described_class.create
      table.add_header(%w[Name Age City])
      table.add_row(['John', '25', 'New York'])
      table.add_row(%w[Alice 30 London])

      expected = {
        'type' => 'table',
        'content' => [{
          'type' => 'table_row',
          'content' => [{
            'type' => 'table_header',
            'content' => [{
              'type' => 'paragraph',
              'content' => [{
                'type' => 'text',
                'text' => 'Name'
              }]
            }]
          }, {
            'type' => 'table_header',
            'content' => [{
              'type' => 'paragraph',
              'content' => [{
                'type' => 'text',
                'text' => 'Age'
              }]
            }]
          }, {
            'type' => 'table_header',
            'content' => [{
              'type' => 'paragraph',
              'content' => [{
                'type' => 'text',
                'text' => 'City'
              }]
            }]
          }]
        }, {
          'type' => 'table_row',
          'content' => [{
            'type' => 'table_cell',
            'content' => [{
              'type' => 'paragraph',
              'content' => [{
                'type' => 'text',
                'text' => 'John'
              }]
            }]
          }, {
            'type' => 'table_cell',
            'content' => [{
              'type' => 'paragraph',
              'content' => [{
                'type' => 'text',
                'text' => '25'
              }]
            }]
          }, {
            'type' => 'table_cell',
            'content' => [{
              'type' => 'paragraph',
              'content' => [{
                'type' => 'text',
                'text' => 'New York'
              }]
            }]
          }]
        }, {
          'type' => 'table_row',
          'content' => [{
            'type' => 'table_cell',
            'content' => [{
              'type' => 'paragraph',
              'content' => [{
                'type' => 'text',
                'text' => 'Alice'
              }]
            }]
          }, {
            'type' => 'table_cell',
            'content' => [{
              'type' => 'paragraph',
              'content' => [{
                'type' => 'text',
                'text' => '30'
              }]
            }]
          }, {
            'type' => 'table_cell',
            'content' => [{
              'type' => 'paragraph',
              'content' => [{
                'type' => 'text',
                'text' => 'London'
              }]
            }]
          }]
        }]
      }

      expect(table.to_h).to eq(expected)
    end

    it 'creates a table with complex cell content' do
      table = described_class.create
      table.add_header(%w[Description Status])

      row = table.add_row
      cell = row.add_cell
      para = cell.add_paragraph('This is ')
      para.add_text('bold', [Prosereflect::Mark::Bold.new])
      para.add_text(' and ')
      para.add_text('italic', [Prosereflect::Mark::Italic.new])
      para.add_hard_break
      para.add_text('text')

      cell = row.add_cell
      para = cell.add_paragraph('Complete')
      para.add_text(' ✓', [Prosereflect::Mark::Bold.new, Prosereflect::Mark::Strike.new])

      expected = {
        'type' => 'table',
        'content' => [{
          'type' => 'table_row',
          'content' => [{
            'type' => 'table_header',
            'content' => [{
              'type' => 'paragraph',
              'content' => [{
                'type' => 'text',
                'text' => 'Description'
              }]
            }]
          }, {
            'type' => 'table_header',
            'content' => [{
              'type' => 'paragraph',
              'content' => [{
                'type' => 'text',
                'text' => 'Status'
              }]
            }]
          }]
        }, {
          'type' => 'table_row',
          'content' => [{
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
                'text' => 'text'
              }]
            }]
          }, {
            'type' => 'table_cell',
            'content' => [{
              'type' => 'paragraph',
              'content' => [{
                'type' => 'text',
                'text' => 'Complete'
              }, {
                'type' => 'text',
                'text' => ' ✓',
                'marks' => [{
                  'type' => 'bold'
                }, {
                  'type' => 'strike'
                }]
              }]
            }]
          }]
        }]
      }

      expect(table.to_h).to eq(expected)
    end
  end

  describe 'table operations' do
    let(:table) do
      t = described_class.create
      t.add_header(%w[Name Age City])
      t.add_row(['John', '25', 'New York'])
      t.add_row(%w[Alice 30 London])
      t
    end

    describe '#rows' do
      it 'returns all rows including header' do
        expect(table.rows.size).to eq(3)
        expect(table.rows).to all(be_a(Prosereflect::TableRow))
        expect(table.rows.first.cells.first).to be_a(Prosereflect::TableHeader)
        expect(table.rows[1].cells.first).to be_a(Prosereflect::TableCell)
      end
    end

    describe '#header_row' do
      it 'returns the first row with header cells' do
        header = table.header_row
        expect(header).to be_a(Prosereflect::TableRow)
        expect(header.cells).to all(be_a(Prosereflect::TableHeader))
        expect(header.cells.map(&:text_content)).to eq(%w[Name Age City])
      end

      it 'returns nil for empty table' do
        empty_table = described_class.create
        expect(empty_table.header_row).to be_nil
      end
    end

    describe '#data_rows' do
      it 'returns all non-header rows' do
        data_rows = table.data_rows
        expect(data_rows.size).to eq(2)
        expect(data_rows).to all(be_a(Prosereflect::TableRow))
        expect(data_rows.first.cells.map(&:text_content)).to eq(['John', '25', 'New York'])
        expect(data_rows.last.cells.map(&:text_content)).to eq(%w[Alice 30 London])
      end
    end

    describe '#cell_at' do
      it 'returns cell at specified position' do
        cell = table.cell_at(0, 1)
        expect(cell).to be_a(Prosereflect::TableCell)
        expect(cell.text_content).to eq('25')
      end

      it 'returns nil for invalid positions' do
        expect(table.cell_at(-1, 0)).to be_nil
        expect(table.cell_at(0, -1)).to be_nil
        expect(table.cell_at(5, 0)).to be_nil
        expect(table.cell_at(0, 5)).to be_nil
      end
    end
  end

  describe 'table building' do
    describe '#add_header' do
      it 'adds a header row with styled cells' do
        table = described_class.create
        header = table.add_header(%w[Title Description])
        header.cells.first.add_text(' (required)', [Prosereflect::Mark::Italic.new])

        expected = {
          'type' => 'table',
          'content' => [{
            'type' => 'table_row',
            'content' => [{
              'type' => 'table_header',
              'content' => [{
                'type' => 'paragraph',
                'content' => [{
                  'type' => 'text',
                  'text' => 'Title'
                }, {
                  'type' => 'text',
                  'text' => ' (required)',
                  'marks' => [{
                    'type' => 'italic'
                  }]
                }]
              }]
            }, {
              'type' => 'table_header',
              'content' => [{
                'type' => 'paragraph',
                'content' => [{
                  'type' => 'text',
                  'text' => 'Description'
                }]
              }]
            }]
          }]
        }

        expect(table.to_h).to eq(expected)
      end
    end

    describe '#add_rows' do
      it 'adds multiple rows with mixed content' do
        table = described_class.create
        table.add_header(%w[Item Status])

        table.add_rows([
                         ['Task 1', 'Done'],
                         ['Task 2', 'Pending']
                       ])

        row = table.add_row
        cell = row.add_cell
        cell.add_paragraph('Task 3')
        cell = row.add_cell
        para = cell.add_paragraph
        para.add_text('In Progress', [Prosereflect::Mark::Bold.new])

        expected = {
          'type' => 'table',
          'content' => [{
            'type' => 'table_row',
            'content' => [{
              'type' => 'table_header',
              'content' => [{
                'type' => 'paragraph',
                'content' => [{
                  'type' => 'text',
                  'text' => 'Item'
                }]
              }]
            }, {
              'type' => 'table_header',
              'content' => [{
                'type' => 'paragraph',
                'content' => [{
                  'type' => 'text',
                  'text' => 'Status'
                }]
              }]
            }]
          }, {
            'type' => 'table_row',
            'content' => [{
              'type' => 'table_cell',
              'content' => [{
                'type' => 'paragraph',
                'content' => [{
                  'type' => 'text',
                  'text' => 'Task 1'
                }]
              }]
            }, {
              'type' => 'table_cell',
              'content' => [{
                'type' => 'paragraph',
                'content' => [{
                  'type' => 'text',
                  'text' => 'Done'
                }]
              }]
            }]
          }, {
            'type' => 'table_row',
            'content' => [{
              'type' => 'table_cell',
              'content' => [{
                'type' => 'paragraph',
                'content' => [{
                  'type' => 'text',
                  'text' => 'Task 2'
                }]
              }]
            }, {
              'type' => 'table_cell',
              'content' => [{
                'type' => 'paragraph',
                'content' => [{
                  'type' => 'text',
                  'text' => 'Pending'
                }]
              }]
            }]
          }, {
            'type' => 'table_row',
            'content' => [{
              'type' => 'table_cell',
              'content' => [{
                'type' => 'paragraph',
                'content' => [{
                  'type' => 'text',
                  'text' => 'Task 3'
                }]
              }]
            }, {
              'type' => 'table_cell',
              'content' => [{
                'type' => 'paragraph',
                'content' => [{
                  'type' => 'text',
                  'text' => 'In Progress',
                  'marks' => [{
                    'type' => 'bold'
                  }]
                }]
              }]
            }]
          }]
        }

        expect(table.to_h).to eq(expected)
      end
    end
  end

  describe 'serialization' do
    it 'converts to hash representation' do
      table = described_class.new
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
