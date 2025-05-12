# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Prosemirror::Paragraph do
  describe 'initialization' do
    it 'initializes as a paragraph node' do
      paragraph = described_class.new({ 'type' => 'paragraph' })
      expect(paragraph.type).to eq('paragraph')
    end
  end

  describe '.create' do
    it 'creates an empty paragraph' do
      paragraph = described_class.create
      expect(paragraph).to be_a(described_class)
      expect(paragraph.type).to eq('paragraph')
      expect(paragraph.content).to be_empty
    end

    it 'creates a paragraph with attributes' do
      attrs = { 'align' => 'center' }
      paragraph = described_class.create(attrs)
      expect(paragraph.attrs).to eq(attrs)
    end
  end

  describe '#text_nodes' do
    it 'returns all text nodes in the paragraph' do
      paragraph = described_class.create
      paragraph.add_text('First text')
      paragraph.add_text('Second text')

      expect(paragraph.text_nodes.size).to eq(2)
      expect(paragraph.text_nodes).to all(be_a(Prosemirror::Text))
    end

    it 'returns empty array for paragraph with no text nodes' do
      paragraph = described_class.create
      expect(paragraph.text_nodes).to eq([])
    end
  end

  describe '#text_content' do
    it 'returns concatenated text from all text nodes' do
      paragraph = described_class.create
      paragraph.add_text('First text')
      paragraph.add_text(' Second text')

      expect(paragraph.text_content).to eq('First text Second text')
    end

    it 'returns empty string for empty paragraph' do
      paragraph = described_class.create
      expect(paragraph.text_content).to eq('')
    end

    it 'handles hard breaks' do
      paragraph = described_class.create
      paragraph.add_text('First line')
      paragraph.add_hard_break
      paragraph.add_text('Second line')

      expect(paragraph.text_content).to eq("First line\nSecond line")
    end

    it 'handles mixed content types' do
      paragraph = described_class.create
      paragraph.add_text('Text with ')

      # Add a custom node that is neither text nor hard_break
      custom_node = Prosemirror::Node.create('custom_node')
      custom_node.instance_eval do
        def text_content
          'custom content'
        end
      end
      paragraph.add_child(custom_node)

      expect(paragraph.text_content).to eq('Text with custom content')
    end
  end

  describe '#add_text' do
    it 'adds text to the paragraph' do
      paragraph = described_class.create
      text_node = paragraph.add_text('Hello world')

      expect(paragraph.content.size).to eq(1)
      expect(text_node).to be_a(Prosemirror::Text)
      expect(text_node.text).to eq('Hello world')
    end

    it 'adds text with marks' do
      paragraph = described_class.create
      marks = [{ 'type' => 'bold' }]
      text_node = paragraph.add_text('Bold text', marks)

      expect(text_node.marks).to eq(marks)
    end

    it 'does not add empty text' do
      paragraph = described_class.create
      result = paragraph.add_text('')

      expect(paragraph.content).to be_empty
      expect(result).to be_nil
    end

    it 'does not add nil text' do
      paragraph = described_class.create
      result = paragraph.add_text(nil)

      expect(paragraph.content).to be_empty
      expect(result).to be_nil
    end
  end

  describe '#add_hard_break' do
    it 'adds a hard break to the paragraph' do
      paragraph = described_class.create
      hard_break = paragraph.add_hard_break

      expect(paragraph.content.size).to eq(1)
      expect(hard_break).to be_a(Prosemirror::HardBreak)
    end

    it 'adds a hard break with marks' do
      paragraph = described_class.create
      marks = [{ 'type' => 'italic' }]
      hard_break = paragraph.add_hard_break(marks)

      expect(hard_break.marks).to eq(marks)
    end
  end

  describe 'serialization' do
    it 'converts to hash representation' do
      paragraph = described_class.create
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
  end
end
