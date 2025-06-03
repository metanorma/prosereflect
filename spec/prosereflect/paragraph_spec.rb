# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Prosereflect::Paragraph do
  describe 'initialization' do
    it 'initializes as a paragraph node' do
      paragraph = described_class.new({ 'type' => 'paragraph' })
      expect(paragraph.type).to eq('paragraph')
    end

    it 'initializes with content' do
      text_node = Prosereflect::Text.new(text: 'Hello')
      paragraph = described_class.new
      paragraph.add_child(text_node)

      expect(paragraph.content.first).to be_a(Prosereflect::Text)
      expect(paragraph.content.first.text).to eq('Hello')
    end

    it 'initializes with complex content' do
      content = [
        { 'type' => 'text', 'text' => 'Hello', 'marks' => [{ 'type' => 'bold' }] }
      ]
      paragraph = described_class.new(content: content)

      expect(paragraph.content[0].raw_marks.first.type).to eq('bold')
    end
  end

  describe '.create' do
    it 'creates a simple paragraph with text' do
      paragraph = described_class.new
      paragraph.add_text('This is a test paragraph.')

      expected = {
        'type' => 'paragraph',
        'content' => [{
          'type' => 'text',
          'text' => 'This is a test paragraph.'
        }]
      }

      expect(paragraph.to_h).to eq(expected)
    end

    it 'creates a paragraph with styled text' do
      paragraph = described_class.new
      paragraph.add_text('This is ')
      paragraph.add_text('bold', [Prosereflect::Mark::Bold.new])
      paragraph.add_text(' and ')
      paragraph.add_text('italic', [Prosereflect::Mark::Italic.new])
      paragraph.add_text(' text.')

      expected = {
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
          'type' => 'text',
          'text' => ' text.'
        }]
      }

      expect(paragraph.to_h).to eq(expected)
    end

    it 'creates a paragraph with multiple text styles' do
      paragraph = described_class.new
      paragraph.add_text('This is ')
      paragraph.add_text('struck', [Prosereflect::Mark::Strike.new])
      paragraph.add_text(' and ')
      paragraph.add_text('underlined', [Prosereflect::Mark::Underline.new])
      paragraph.add_text(' and ')
      paragraph.add_text('sub', [Prosereflect::Mark::Subscript.new])
      paragraph.add_text(' and ')
      paragraph.add_text('super', [Prosereflect::Mark::Superscript.new])
      paragraph.add_text(' text.')

      expected = {
        'type' => 'paragraph',
        'content' => [{
          'type' => 'text',
          'text' => 'This is '
        }, {
          'type' => 'text',
          'text' => 'struck',
          'marks' => [{
            'type' => 'strike'
          }]
        }, {
          'type' => 'text',
          'text' => ' and '
        }, {
          'type' => 'text',
          'text' => 'underlined',
          'marks' => [{
            'type' => 'underline'
          }]
        }, {
          'type' => 'text',
          'text' => ' and '
        }, {
          'type' => 'text',
          'text' => 'sub',
          'marks' => [{
            'type' => 'subscript'
          }]
        }, {
          'type' => 'text',
          'text' => ' and '
        }, {
          'type' => 'text',
          'text' => 'super',
          'marks' => [{
            'type' => 'superscript'
          }]
        }, {
          'type' => 'text',
          'text' => ' text.'
        }]
      }

      expect(paragraph.to_h).to eq(expected)
    end

    it 'creates a paragraph with mixed text styles' do
      paragraph = described_class.new
      paragraph.add_text('Bold and italic', [
                           Prosereflect::Mark::Bold.new,
                           Prosereflect::Mark::Italic.new
                         ])
      paragraph.add_text(' and ')
      paragraph.add_text('underlined and struck', [
                           Prosereflect::Mark::Underline.new,
                           Prosereflect::Mark::Strike.new
                         ])

      expected = {
        'type' => 'paragraph',
        'content' => [{
          'type' => 'text',
          'text' => 'Bold and italic',
          'marks' => [{
            'type' => 'bold'
          }, {
            'type' => 'italic'
          }]
        }, {
          'type' => 'text',
          'text' => ' and '
        }, {
          'type' => 'text',
          'text' => 'underlined and struck',
          'marks' => [{
            'type' => 'underline'
          }, {
            'type' => 'strike'
          }]
        }]
      }

      expect(paragraph.to_h).to eq(expected)
    end

    it 'creates a paragraph with line breaks' do
      paragraph = described_class.new
      paragraph.add_text('First line')
      paragraph.add_hard_break
      paragraph.add_text('Second line')
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
          'text' => 'Second line'
        }, {
          'type' => 'hard_break'
        }, {
          'type' => 'text',
          'text' => 'Third line'
        }]
      }

      expect(paragraph.to_h).to eq(expected)
    end

    it 'creates a paragraph with alignment' do
      paragraph = described_class.new(attrs: { 'align' => 'center' })
      paragraph.add_text('Centered text')

      expected = {
        'type' => 'paragraph',
        'attrs' => {
          'align' => 'center'
        },
        'content' => [{
          'type' => 'text',
          'text' => 'Centered text'
        }]
      }

      expect(paragraph.to_h).to eq(expected)
    end

    it 'creates a paragraph with complex content' do
      paragraph = described_class.new
      paragraph.add_text('A formula: ')
      paragraph.add_text('H', [Prosereflect::Mark::Bold.new])
      paragraph.add_text('2', [Prosereflect::Mark::Subscript.new])
      paragraph.add_text('O + 2H')
      paragraph.add_text('2', [Prosereflect::Mark::Subscript.new])
      paragraph.add_text(' → 2H')
      paragraph.add_text('2', [Prosereflect::Mark::Subscript.new])
      paragraph.add_text('O')

      expected = {
        'type' => 'paragraph',
        'content' => [{
          'type' => 'text',
          'text' => 'A formula: '
        }, {
          'type' => 'text',
          'text' => 'H',
          'marks' => [{
            'type' => 'bold'
          }]
        }, {
          'type' => 'text',
          'text' => '2',
          'marks' => [{
            'type' => 'subscript'
          }]
        }, {
          'type' => 'text',
          'text' => 'O + 2H'
        }, {
          'type' => 'text',
          'text' => '2',
          'marks' => [{
            'type' => 'subscript'
          }]
        }, {
          'type' => 'text',
          'text' => ' → 2H'
        }, {
          'type' => 'text',
          'text' => '2',
          'marks' => [{
            'type' => 'subscript'
          }]
        }, {
          'type' => 'text',
          'text' => 'O'
        }]
      }

      expect(paragraph.to_h).to eq(expected)
    end

    it 'creates a paragraph with mathematical expressions' do
      paragraph = described_class.new
      paragraph.add_text('The quadratic formula: x = -b ± ')
      paragraph.add_text('√', [Prosereflect::Mark::Bold.new])
      paragraph.add_text('(b')
      paragraph.add_text('2', [Prosereflect::Mark::Superscript.new])
      paragraph.add_text(' - 4ac) / 2a')

      expected = {
        'type' => 'paragraph',
        'content' => [{
          'type' => 'text',
          'text' => 'The quadratic formula: x = -b ± '
        }, {
          'type' => 'text',
          'text' => '√',
          'marks' => [{
            'type' => 'bold'
          }]
        }, {
          'type' => 'text',
          'text' => '(b'
        }, {
          'type' => 'text',
          'text' => '2',
          'marks' => [{
            'type' => 'superscript'
          }]
        }, {
          'type' => 'text',
          'text' => ' - 4ac) / 2a'
        }]
      }

      expect(paragraph.to_h).to eq(expected)
    end
  end

  describe '#text_nodes' do
    it 'returns all text nodes in the paragraph' do
      paragraph = described_class.new
      paragraph.add_text('First text')
      paragraph.add_text('Second text')

      expect(paragraph.text_nodes.size).to eq(2)
      expect(paragraph.text_nodes).to all(be_a(Prosereflect::Text))
    end

    it 'returns empty array for paragraph with no text nodes' do
      paragraph = described_class.new
      expect(paragraph.text_nodes).to eq([])
    end

    it 'returns text nodes with marks' do
      paragraph = described_class.new
      paragraph.add_text('Hello', [Prosereflect::Mark::Bold.new])

      expect(paragraph.text_nodes[0].raw_marks.first.type).to eq('bold')
    end

    it 'ignores non-text nodes' do
      paragraph = described_class.new
      paragraph.add_text('Text')
      paragraph.add_hard_break
      paragraph.add_text('More text')

      expect(paragraph.text_nodes.size).to eq(2)
      expect(paragraph.text_nodes.map(&:text)).to eq(['Text', 'More text'])
    end
  end

  describe '#text_content' do
    it 'returns plain text content without marks' do
      paragraph = described_class.new
      paragraph.add_text('This is ')
      paragraph.add_text('bold', [Prosereflect::Mark::Bold.new])
      paragraph.add_text(' and ')
      paragraph.add_text('italic', [Prosereflect::Mark::Italic.new])
      paragraph.add_text(' text.')

      expect(paragraph.text_content).to eq('This is bold and italic text.')
    end

    it 'handles line breaks in text content' do
      paragraph = described_class.new
      paragraph.add_text('First line')
      paragraph.add_hard_break
      paragraph.add_text('Second line')

      expect(paragraph.text_content).to eq("First line\nSecond line")
    end

    it 'handles empty paragraphs' do
      paragraph = described_class.new
      expect(paragraph.text_content).to eq('')
    end
  end

  describe '#add_text' do
    it 'adds text to the paragraph' do
      paragraph = described_class.new
      text_node = paragraph.add_text('Hello world')

      expect(paragraph.content.size).to eq(1)
      expect(text_node).to be_a(Prosereflect::Text)
      expect(text_node.text).to eq('Hello world')
    end

    it 'adds text with marks' do
      paragraph = described_class.new
      marks = [Prosereflect::Mark::Bold.new]
      text_node = paragraph.add_text('Hello', marks)

      expect(text_node.raw_marks).to eq(marks)
    end

    it 'adds text with multiple marks' do
      paragraph = described_class.new
      marks = [
        Prosereflect::Mark::Bold.new,
        Prosereflect::Mark::Italic.new,
        Prosereflect::Mark::Underline.new
      ]
      text_node = paragraph.add_text('Hello', marks)

      expect(text_node.raw_marks.map(&:type)).to eq(%w[bold italic underline])
    end

    it 'does not add empty text' do
      paragraph = described_class.new
      result = paragraph.add_text('')

      expect(paragraph.content).to be_empty
      expect(result).to be_nil
    end

    it 'does not add nil text' do
      paragraph = described_class.new
      result = paragraph.add_text(nil)

      expect(paragraph.content).to be_empty
      expect(result).to be_nil
    end

    it 'preserves existing content when adding text' do
      paragraph = described_class.new
      paragraph.add_text('First')
      paragraph.add_hard_break
      paragraph.add_text('Second')

      expect(paragraph.content.size).to eq(3)
      expect(paragraph.text_content).to eq("First\nSecond")
    end
  end

  describe '#add_hard_break' do
    it 'adds a hard break to the paragraph' do
      paragraph = described_class.new
      hard_break = paragraph.add_hard_break

      expect(paragraph.content.size).to eq(1)
      expect(hard_break).to be_a(Prosereflect::HardBreak)
    end

    it 'adds a hard break with marks' do
      paragraph = described_class.new
      marks = [Prosereflect::Mark::Italic.new]
      hard_break = paragraph.add_hard_break(marks)

      expect(hard_break.raw_marks).to eq(marks)
    end

    it 'adds multiple hard breaks' do
      paragraph = described_class.new
      paragraph.add_hard_break
      paragraph.add_hard_break
      paragraph.add_hard_break

      expect(paragraph.content.size).to eq(3)
      expect(paragraph.content).to all(be_a(Prosereflect::HardBreak))
    end

    it 'preserves existing content when adding hard breaks' do
      paragraph = described_class.new
      paragraph.add_text('Text')
      paragraph.add_hard_break
      paragraph.add_text('More')

      expect(paragraph.content.size).to eq(3)
      expect(paragraph.text_content).to eq("Text\nMore")
    end
  end

  describe 'serialization' do
    it 'converts to hash representation' do
      paragraph = described_class.new
      paragraph.add_text('Hello')
      paragraph.add_hard_break
      paragraph.add_text('World')

      hash = paragraph.to_h
      expect(hash['type']).to eq('paragraph')
      expect(hash['content'].size).to eq(3)
      expect(hash['content'][0]['type']).to eq('text')
      expect(hash['content'][1]['type']).to eq('hard_break')
      expect(hash['content'][2]['type']).to eq('text')
    end

    it 'converts to hash with marks' do
      paragraph = described_class.new
      paragraph.add_text('Bold', [Prosereflect::Mark::Bold.new])
      paragraph.add_text(' and ')
      paragraph.add_text('italic', [Prosereflect::Mark::Italic.new])

      hash = paragraph.to_h
      expect(hash['content'][0]['marks'][0]['type']).to eq('bold')
      expect(hash['content'][2]['marks'][0]['type']).to eq('italic')
    end

    it 'converts to hash with attributes' do
      paragraph = described_class.new(attrs: { 'align' => 'center' })
      paragraph.add_text('Centered text')

      hash = paragraph.to_h
      expect(hash['attrs']).to eq({ 'align' => 'center' })
    end

    it 'converts complex content to hash' do
      paragraph = described_class.new
      paragraph.add_text('Mixed', [
                           Prosereflect::Mark::Bold.new,
                           Prosereflect::Mark::Italic.new
                         ])
      paragraph.add_hard_break([Prosereflect::Mark::Strike.new])
      paragraph.add_text('Styles')

      hash = paragraph.to_h
      expect(hash['content'].size).to eq(3)
      expect(hash['content'][0]['marks'].size).to eq(2)
      expect(hash['content'][1]['marks'].size).to eq(1)
      expect(hash['content'][2]['marks']).to be_nil
    end
  end
end
