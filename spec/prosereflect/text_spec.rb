# frozen_string_literal: true

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
      marks = [{ 'type' => 'bold' }, { 'type' => 'italic' }]
      text = described_class.new({
                                   'type' => 'text',
                                   'text' => 'Formatted text',
                                   'marks' => marks
                                 })

      expect(text.marks).to eq(marks)
    end
  end

  describe '.create' do
    it 'creates a text node with content' do
      text = described_class.new(text: 'Hello world')
      expect(text.type).to eq('text')
      expect(text.text).to eq('Hello world')
    end

    it 'creates a text node with marks' do
      marks = [{ 'type' => 'bold' }]
      text = described_class.new(text: 'Bold text', marks: marks)

      expect(text.text).to eq('Bold text')
      expect(text.marks).to eq(marks)
    end
  end

  describe '#text_content' do
    it 'returns the text content' do
      text = described_class.new({ 'type' => 'text', 'text' => 'Sample text' })
      expect(text.text_content).to eq('Sample text')
    end

    it 'returns empty string when text is nil' do
      text = described_class.new({ 'type' => 'text' })
      expect(text.text_content).to eq('')
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
      marks = [{ 'type' => 'bold' }]
      text = described_class.new({
                                   'type' => 'text',
                                   'text' => 'Bold text',
                                   'marks' => marks
                                 })

      hash = text.to_h
      expect(hash['marks']).to eq(marks)
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
      marks = [
        { 'type' => 'bold' },
        { 'type' => 'italic' },
        { 'type' => 'underline' }
      ]

      text = described_class.new({
                                   'type' => 'text',
                                   'text' => 'Formatted text',
                                   'marks' => marks
                                 })

      expect(text.marks.size).to eq(3)
    end

    it 'can have marks with attributes' do
      marks = [
        { 'type' => 'link', 'attrs' => { 'href' => 'https://example.com' } }
      ]

      text = described_class.new({
                                   'type' => 'text',
                                   'text' => 'Link text',
                                   'marks' => marks
                                 })

      expect(text.marks[0]['attrs']['href']).to eq('https://example.com')
    end
  end
end
