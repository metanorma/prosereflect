# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Prosereflect::Text do
  describe 'initialization' do
    it 'initializes as a text node' do
      text = described_class.new({ 'type' => 'text', 'text' => 'Hello' })
      expect(text.type).to eq('text')
      expect(text.text).to eq('Hello')
    end

    it 'initializes with empty text' do
      text = described_class.new({ 'type' => 'text' })
      expect(text.text).to eq('')
    end

    it 'initializes with marks' do
      marks = [
        Prosereflect::Mark::Bold.new,
        Prosereflect::Mark::Italic.new
      ]
      text = described_class.new(text: 'Hello', marks: marks)

      expect(text.raw_marks).to eq(marks)
    end
  end

  describe '.create' do
    it 'creates a simple text node' do
      text = described_class.create('Hello world')

      expected = {
        'type' => 'text',
        'text' => 'Hello world'
      }

      expect(text.to_h).to eq(expected)
    end

    it 'creates a text node with marks' do
      text = described_class.create('Formatted text', [
                                      Prosereflect::Mark::Bold.new,
                                      Prosereflect::Mark::Italic.new
                                    ])

      expected = {
        'type' => 'text',
        'text' => 'Formatted text',
        'marks' => [
          { 'type' => 'bold' },
          { 'type' => 'italic' }
        ]
      }

      expect(text.to_h).to eq(expected)
    end

    it 'creates a text node with marks and attributes' do
      text = described_class.create('Link text', [
                                      Prosereflect::Mark::Link.new(attrs: { 'href' => 'https://example.com', 'title' => 'Example' }),
                                      Prosereflect::Mark::Bold.new
                                    ])

      expected = {
        'type' => 'text',
        'text' => 'Link text',
        'marks' => [
          {
            'type' => 'link',
            'attrs' => {
              'href' => 'https://example.com',
              'title' => 'Example'
            }
          },
          { 'type' => 'bold' }
        ]
      }

      expect(text.to_h).to eq(expected)
    end
  end

  describe 'text structure' do
    it 'creates text with special characters' do
      text = described_class.create('Special chars: →, ←, ©, ®, ™')

      expected = {
        'type' => 'text',
        'text' => 'Special chars: →, ←, ©, ®, ™'
      }

      expect(text.to_h).to eq(expected)
    end

    it 'creates text with multiple marks and attributes' do
      text = described_class.create('Complex text', [
                                      Prosereflect::Mark::Bold.new,
                                      Prosereflect::Mark::Italic.new,
                                      Prosereflect::Mark::Strike.new,
                                      Prosereflect::Mark::Link.new(attrs: { 'href' => 'https://example.com' }),
                                      Prosereflect::Mark::Underline.new
                                    ])

      expected = {
        'type' => 'text',
        'text' => 'Complex text',
        'marks' => [
          { 'type' => 'bold' },
          { 'type' => 'italic' },
          { 'type' => 'strike' },
          {
            'type' => 'link',
            'attrs' => {
              'href' => 'https://example.com'
            }
          },
          { 'type' => 'underline' }
        ]
      }

      expect(text.to_h).to eq(expected)
    end
  end

  describe 'text operations' do
    describe '#text_content' do
      it 'returns the text content regardless of marks' do
        text = described_class.create('Sample text', [
                                        Prosereflect::Mark::Bold.new,
                                        Prosereflect::Mark::Italic.new
                                      ])

        expect(text.text_content).to eq('Sample text')
      end

      it 'returns empty string for empty text' do
        text = described_class.create('')
        expect(text.text_content).to eq('')
      end

      it 'preserves whitespace and special characters' do
        text = described_class.create("  Multiple   spaces  \t\nand\ttabs  ")
        expect(text.text_content).to eq("  Multiple   spaces  \t\nand\ttabs  ")
      end
    end

    describe '#marks' do
      it 'preserves mark order' do
        text = described_class.new(text: 'Hello')
        marks = [
          Prosereflect::Mark::Bold.new,
          Prosereflect::Mark::Italic.new,
          Prosereflect::Mark::Strike.new
        ]
        text.marks = marks

        expect(text.raw_marks.map(&:type)).to eq(%w[bold italic strike])
      end

      it 'handles empty marks array' do
        text = described_class.create('No marks', [])
        expect(text.marks).to eq([])
        expect(text.to_h).not_to have_key('marks')
      end

      it 'handles nil marks' do
        text = described_class.create('No marks', nil)
        expect(text.marks).to be_nil
        expect(text.to_h).not_to have_key('marks')
      end
    end
  end

  describe 'mark attributes' do
    it 'preserves mark attributes in serialization' do
      text = described_class.create('Styled text', [
                                      Prosereflect::Mark::Link.new(attrs: {
                                                                     'href' => 'https://example.com',
                                                                     'title' => 'Example Link',
                                                                     'target' => '_blank'
                                                                   }),
                                      Prosereflect::Mark::Bold.new,
                                      Prosereflect::Mark::Italic.new
                                    ])

      expected = {
        'type' => 'text',
        'text' => 'Styled text',
        'marks' => [
          {
            'type' => 'link',
            'attrs' => {
              'href' => 'https://example.com',
              'title' => 'Example Link',
              'target' => '_blank'
            }
          },
          { 'type' => 'bold' },
          { 'type' => 'italic' }
        ]
      }

      expect(text.to_h).to eq(expected)
    end

    it 'handles marks with empty attributes' do
      text = described_class.create('Test text', [
                                      Prosereflect::Mark::Link.new(attrs: {}),
                                      Prosereflect::Mark::Bold.new,
                                      Prosereflect::Mark::Italic.new
                                    ])

      expected = {
        'type' => 'text',
        'text' => 'Test text',
        'marks' => [
          { 'type' => 'link' },
          { 'type' => 'bold' },
          { 'type' => 'italic' }
        ]
      }

      expect(text.to_h).to eq(expected)
    end
  end

  describe '#to_h' do
    it 'creates a hash representation with text' do
      text = described_class.new({ 'type' => 'text', 'text' => 'Hello' })
      hash = text.to_h

      expect(hash['type']).to eq('text')
      expect(hash['text']).to eq('Hello')
    end

    it 'includes marks in hash representation when present' do
      mark = Prosereflect::Mark::Base.new(type: 'bold')
      marks = [mark]
      text = described_class.new(text: 'Bold text', marks: marks)

      hash = text.to_h
      expect(hash['marks']).to eq([{ 'type' => 'bold' }])
    end
  end

  describe 'inheritance' do
    it 'is a Node' do
      text = described_class.new({ 'type' => 'text', 'text' => 'Test' })
      expect(text).to be_a(Prosereflect::Node)
    end
  end

  describe 'with marks' do
    it 'can have multiple marks' do
      bold_mark = Prosereflect::Mark::Base.new(type: 'bold')
      italic_mark = Prosereflect::Mark::Base.new(type: 'italic')
      underline_mark = Prosereflect::Mark::Base.new(type: 'underline')
      marks = [bold_mark, italic_mark, underline_mark]

      text = described_class.new(text: 'Formatted text', marks: marks)

      expect(text.marks.size).to eq(3)
    end

    it 'can have marks with attributes' do
      text = described_class.new(text: 'Hello')
      mark = Prosereflect::Mark::Link.new(attrs: { 'href' => 'https://example.com' })
      text.marks = [mark]

      expect(text.raw_marks[0].attrs['href']).to eq('https://example.com')
    end
  end
end
