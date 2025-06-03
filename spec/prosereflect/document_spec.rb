# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Prosereflect::Document do
  let(:fixtures_path) { File.join(__dir__, '..', 'fixtures') }
  let(:yaml_file) { File.join(fixtures_path, 'ituob-1000', 'ituob-1000-DP.yaml') }
  let(:file_content) { File.read(yaml_file) }
  let(:document) { Prosereflect::Parser.parse_document(YAML.safe_load(file_content)) }

  describe 'basic properties' do
    it 'has the correct type' do
      expect(document.type).to eq('doc')
    end

    it 'is a node' do
      expect(document).to be_a(Prosereflect::Node)
    end
  end

  describe '.create' do
    it 'creates a simple document with a paragraph' do
      document = described_class.new
      document.add_paragraph('This is a test paragraph.')

      expected = {
        'type' => 'doc',
        'content' => [{
          'type' => 'paragraph',
          'content' => [{
            'type' => 'text',
            'text' => 'This is a test paragraph.'
          }]
        }]
      }

      expect(document.to_h).to eq(expected)
    end

    it 'creates a document with multiple paragraphs and styles' do
      document = described_class.new

      # Add a heading
      heading = document.add_heading(1)
      heading.add_text('Document Title')

      # Add paragraphs with different styles
      para1 = document.add_paragraph
      para1.add_text('This is a paragraph with ')
      para1.add_text('bold', [Prosereflect::Mark::Bold.new])
      para1.add_text(' and ')
      para1.add_text('italic', [Prosereflect::Mark::Italic.new])
      para1.add_text(' text.')

      para2 = document.add_paragraph
      para2.add_text('This paragraph has ')
      para2.add_text('underlined', [Prosereflect::Mark::Underline.new])
      para2.add_text(' and ')
      para2.add_text('struck through', [Prosereflect::Mark::Strike.new])
      para2.add_text(' text.')

      expected = {
        'type' => 'doc',
        'content' => [{
          'type' => 'heading',
          'attrs' => { 'level' => 1 },
          'content' => [{
            'type' => 'text',
            'text' => 'Document Title'
          }]
        }, {
          'type' => 'paragraph',
          'content' => [{
            'type' => 'text',
            'text' => 'This is a paragraph with '
          }, {
            'type' => 'text',
            'text' => 'bold',
            'marks' => [{ 'type' => 'bold' }]
          }, {
            'type' => 'text',
            'text' => ' and '
          }, {
            'type' => 'text',
            'text' => 'italic',
            'marks' => [{ 'type' => 'italic' }]
          }, {
            'type' => 'text',
            'text' => ' text.'
          }]
        }, {
          'type' => 'paragraph',
          'content' => [{
            'type' => 'text',
            'text' => 'This paragraph has '
          }, {
            'type' => 'text',
            'text' => 'underlined',
            'marks' => [{ 'type' => 'underline' }]
          }, {
            'type' => 'text',
            'text' => ' and '
          }, {
            'type' => 'text',
            'text' => 'struck through',
            'marks' => [{ 'type' => 'strike' }]
          }, {
            'type' => 'text',
            'text' => ' text.'
          }]
        }]
      }

      expect(document.to_h).to eq(expected)
    end

    it 'creates a document with tables and lists' do
      document = described_class.new

      # Add a table
      table = document.add_table
      table.add_header(%w[Product Price Quantity])
      table.add_row(['Widget', '$10.00', '5'])
      table.add_row(['Gadget', '$15.00', '3'])

      # Add an ordered list
      list = document.add_ordered_list
      list.start = 1
      list.add_item('First item')
      list.add_item('Second item with ')
          .add_text('emphasis', [Prosereflect::Mark::Italic.new])

      expected = {
        'type' => 'doc',
        'content' => [{
          'type' => 'table',
          'content' => [{
            'type' => 'table_row',
            'content' => [{
              'type' => 'table_header',
              'content' => [{
                'type' => 'paragraph',
                'content' => [{
                  'type' => 'text',
                  'text' => 'Product'
                }]
              }]
            }, {
              'type' => 'table_header',
              'content' => [{
                'type' => 'paragraph',
                'content' => [{
                  'type' => 'text',
                  'text' => 'Price'
                }]
              }]
            }, {
              'type' => 'table_header',
              'content' => [{
                'type' => 'paragraph',
                'content' => [{
                  'type' => 'text',
                  'text' => 'Quantity'
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
                  'text' => 'Widget'
                }]
              }]
            }, {
              'type' => 'table_cell',
              'content' => [{
                'type' => 'paragraph',
                'content' => [{
                  'type' => 'text',
                  'text' => '$10.00'
                }]
              }]
            }, {
              'type' => 'table_cell',
              'content' => [{
                'type' => 'paragraph',
                'content' => [{
                  'type' => 'text',
                  'text' => '5'
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
                  'text' => 'Gadget'
                }]
              }]
            }, {
              'type' => 'table_cell',
              'content' => [{
                'type' => 'paragraph',
                'content' => [{
                  'type' => 'text',
                  'text' => '$15.00'
                }]
              }]
            }, {
              'type' => 'table_cell',
              'content' => [{
                'type' => 'paragraph',
                'content' => [{
                  'type' => 'text',
                  'text' => '3'
                }]
              }]
            }]
          }]
        }, {
          'type' => 'ordered_list',
          'attrs' => { 'start' => 1 },
          'content' => [{
            'type' => 'list_item',
            'content' => [{
              'type' => 'paragraph',
              'content' => [{
                'type' => 'text',
                'text' => 'First item'
              }]
            }]
          }, {
            'type' => 'list_item',
            'content' => [{
              'type' => 'paragraph',
              'content' => [{
                'type' => 'text',
                'text' => 'Second item with '
              }, {
                'type' => 'text',
                'text' => 'emphasis',
                'marks' => [{ 'type' => 'italic' }]
              }]
            }]
          }]
        }]
      }

      expect(document.to_h).to eq(expected)
    end

    it 'creates a document with code blocks and blockquotes' do
      document = described_class.create
      wrapper = document.add_code_block_wrapper
      wrapper.line_numbers = true

      code_block = wrapper.add_code_block
      code_block.language = 'ruby'
      code_block.content = "def example\n  puts 'Hello'\nend"

      quote = document.add_blockquote
      quote.citation = 'https://example.com'
      quote.add_paragraph('A test quote')

      expected = {
        'type' => 'doc',
        'content' => [{
          'type' => 'code_block_wrapper',
          'attrs' => {
            'line_numbers' => true
          },
          'content' => [{
            'type' => 'code_block',
            'attrs' => {
              'content' => "def example\n  puts 'Hello'\nend",
              'language' => 'ruby'
            }
          }]
        }, {
          'type' => 'blockquote',
          'attrs' => {
            'citation' => 'https://example.com'
          },
          'content' => [{
            'type' => 'paragraph',
            'content' => [{
              'type' => 'text',
              'text' => 'A test quote'
            }]
          }]
        }]
      }

      expect(document.to_h).to eq(expected)
    end

    it 'creates a document with mathematical content' do
      document = described_class.new

      # Add a heading
      heading = document.add_heading(2)
      heading.add_text('Mathematical Expressions')

      # Add equations
      para1 = document.add_paragraph
      para1.add_text('The quadratic formula: x = -b ± ')
      para1.add_text('√', [Prosereflect::Mark::Bold.new])
      para1.add_text('(b')
      para1.add_text('2', [Prosereflect::Mark::Superscript.new])
      para1.add_text(' - 4ac) / 2a')

      para2 = document.add_paragraph
      para2.add_text('Water molecule: H')
      para2.add_text('2', [Prosereflect::Mark::Subscript.new])
      para2.add_text('O')

      expected = {
        'type' => 'doc',
        'content' => [{
          'type' => 'heading',
          'attrs' => { 'level' => 2 },
          'content' => [{
            'type' => 'text',
            'text' => 'Mathematical Expressions'
          }]
        }, {
          'type' => 'paragraph',
          'content' => [{
            'type' => 'text',
            'text' => 'The quadratic formula: x = -b ± '
          }, {
            'type' => 'text',
            'text' => '√',
            'marks' => [{ 'type' => 'bold' }]
          }, {
            'type' => 'text',
            'text' => '(b'
          }, {
            'type' => 'text',
            'text' => '2',
            'marks' => [{ 'type' => 'superscript' }]
          }, {
            'type' => 'text',
            'text' => ' - 4ac) / 2a'
          }]
        }, {
          'type' => 'paragraph',
          'content' => [{
            'type' => 'text',
            'text' => 'Water molecule: H'
          }, {
            'type' => 'text',
            'text' => '2',
            'marks' => [{ 'type' => 'subscript' }]
          }, {
            'type' => 'text',
            'text' => 'O'
          }]
        }]
      }

      expect(document.to_h).to eq(expected)
    end

    it 'creates a document with images and links' do
      document = described_class.new

      # Add an image
      image = document.add_image('example.jpg', 'Example image')
      image.title = 'A beautiful landscape'
      image.width = 800
      image.height = 600

      # Add a paragraph with links
      para = document.add_paragraph
      para.add_text('Visit our ')
      link_text = Prosereflect::Text.new(text: 'website')
      link_mark = Prosereflect::Mark::Link.new
      link_mark.attrs = { 'href' => 'https://example.com' }
      link_text.marks = [link_mark]
      para.add_child(link_text)
      para.add_text(' for more information.')

      expected = {
        'type' => 'doc',
        'content' => [{
          'type' => 'image',
          'attrs' => {
            'src' => 'example.jpg',
            'alt' => 'Example image',
            'title' => 'A beautiful landscape',
            'width' => 800,
            'height' => 600
          }
        }, {
          'type' => 'paragraph',
          'content' => [{
            'type' => 'text',
            'text' => 'Visit our '
          }, {
            'type' => 'text',
            'text' => 'website',
            'marks' => [{
              'type' => 'link',
              'attrs' => {
                'href' => 'https://example.com'
              }
            }]
          }, {
            'type' => 'text',
            'text' => ' for more information.'
          }]
        }]
      }

      expect(document.to_h).to eq(expected)
    end
  end

  describe '#paragraphs' do
    it 'returns all paragraphs in the document' do
      doc = described_class.new
      doc.add_paragraph('First paragraph')
      doc.add_paragraph('Second paragraph')

      expect(doc.paragraphs.size).to eq(2)
      expect(doc.paragraphs).to all(be_a(Prosereflect::Paragraph))
    end
  end

  describe '#tables' do
    it 'returns all tables in the document' do
      doc = described_class.new
      doc.add_table
      doc.add_table

      expect(doc.tables.size).to eq(2)
      expect(doc.tables).to all(be_a(Prosereflect::Table))
    end
  end

  describe '#add_paragraph' do
    it 'adds a paragraph with text' do
      doc = described_class.new
      para = doc.add_paragraph('Test paragraph')

      expect(doc.paragraphs.size).to eq(1)
      expect(para).to be_a(Prosereflect::Paragraph)
      expect(para.text_content).to eq('Test paragraph')
    end

    it 'adds an empty paragraph' do
      doc = described_class.new
      para = doc.add_paragraph

      expect(doc.paragraphs.size).to eq(1)
      expect(para).to be_a(Prosereflect::Paragraph)
      expect(para.text_content).to eq('')
    end
  end

  describe '#add_table' do
    it 'adds a table to the document' do
      doc = described_class.new
      table = doc.add_table

      expect(doc.tables.size).to eq(1)
      expect(table).to be_a(Prosereflect::Table)
    end

    it 'adds a table with attributes' do
      doc = described_class.new
      attrs = { 'width' => '100%' }
      table = doc.add_table(attrs)

      expect(table.attrs).to eq(attrs)
    end
  end

  describe 'serialization' do
    it 'converts to hash representation' do
      doc = described_class.new
      doc.add_paragraph('Test paragraph')
      table = doc.add_table
      table.add_header(['Header'])
      table.add_row(['Data'])

      hash = doc.to_h
      expect(hash['type']).to eq('doc')
      expect(hash['content'].size).to eq(2)
      expect(hash['content'][0]['type']).to eq('paragraph')
      expect(hash['content'][1]['type']).to eq('table')
    end

    it 'converts to YAML' do
      doc = described_class.new
      doc.add_paragraph('Test paragraph')

      yaml = doc.to_yaml
      expect(yaml).to be_a(String)
      expect(yaml).to include('type: doc')
      expect(yaml).to include('type: paragraph')
    end

    it 'converts to JSON' do
      doc = described_class.new
      doc.add_paragraph('Test paragraph')

      json = doc.to_json
      expect(json).to be_a(String)
      expect(json).to include('"type":"doc"')
      expect(json).to include('"type":"paragraph"')
    end
  end

  describe '#text_content' do
    it 'returns plain text content from all nodes' do
      document = described_class.new

      # Add various types of content
      document.add_heading(1).add_text('Title')

      para = document.add_paragraph
      para.add_text('This is ')
      para.add_text('bold', [Prosereflect::Mark::Bold.new])
      para.add_text(' text.')

      list = document.add_bullet_list
      list.add_item('First item')
      list.add_item('Second item')

      expected_text = "Title\nThis is bold text.\nFirst item\nSecond item"
      expect(document.text_content).to eq(expected_text)
    end

    it 'handles empty documents' do
      document = described_class.new
      expect(document.text_content).to eq('')
    end
  end
end
