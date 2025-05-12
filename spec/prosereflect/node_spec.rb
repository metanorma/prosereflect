# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Prosereflect::Node do
  describe 'initialization' do
    it 'initializes with empty data' do
      node = described_class.new
      expect(node.type).to be_nil
      expect(node.attrs).to be_nil
      expect(node.content).to be_nil
      expect(node.marks).to be_nil
    end

    # TODO: Update to lutaml-model
    it 'initializes with provided data' do
      data = {
        'type' => 'test_node',
        'attrs' => { 'key' => 'value' },
        'marks' => [{ 'type' => 'bold' }]
      }
      node = described_class.new(data)
      expect(node.type).to eq('test_node')
      expect(node.attrs).to eq({ 'key' => 'value' })
      expect(node.marks).to eq([{ 'type' => 'bold' }])
    end
  end

  describe '#parse_content' do
    it 'returns empty array for nil content' do
      node = described_class.new
      expect(node.parse_content(nil)).to eq([])
    end

    it 'parses content items using Parser' do
      content_data = [
        { 'type' => 'text', 'text' => 'Hello' },
        { 'type' => 'hard_break' }
      ]

      node = described_class.new
      parsed_content = node.parse_content(content_data)

      expect(parsed_content.size).to eq(2)
      expect(parsed_content[0]).to be_a(Prosereflect::Text)
      expect(parsed_content[1]).to be_a(Prosereflect::HardBreak)
    end
  end

  describe '#to_h' do
    it 'creates a hash representation with basic properties' do
      node = described_class.new({ 'type' => 'test_node' })
      hash = node.to_hash

      expect(hash).to be_a(Hash)
      expect(hash['type']).to eq('test_node')
    end

    it 'includes attrs when present' do
      node = described_class.new(
        type: Prosereflect::Text.new(text: 'Hello'),
        attrs: [Prosereflect::Attribute::Href.new('https://example.com')]
      )

      hash = node.to_hash
      expect(hash['attrs']).to eq([{ 'href' => 'https://example.com' }])
    end

    it 'includes marks when present' do
      node = described_class.new(
        type: Prosereflect::Text.new(text: 'Hello'),
        marks: [Prosereflect::Attribute::Bold.new]
      )

      hash = node.to_hash
      expect(hash['marks']).to eq([{ 'type' => 'bold' }])
    end

    it 'includes content when present' do
      node = described_class.new({
                                   'type' => 'test_node',
                                   'content' => [{ 'type' => 'text', 'text' => 'Hello' }]
                                 })

      hash = node.to_hash
      expect(hash['content']).to be_an(Array)
      expect(hash['content'][0]['type']).to eq('text')
    end
  end

  describe '#add_child' do
    it 'adds a child node to content' do
      parent = described_class.new({ 'type' => 'parent' })
      child = described_class.new({ 'type' => 'child' })

      parent.add_child(child)

      expect(parent.content.size).to eq(1)
      expect(parent.content[0]).to eq(child)
    end

    it 'returns the added child' do
      parent = described_class.new({ 'type' => 'parent' })
      child = described_class.new({ 'type' => 'child' })

      result = parent.add_child(child)

      expect(result).to eq(child)
    end
  end

  describe '#find_first' do
    let(:node) do
      root = described_class.new({ 'type' => 'root' })
      para = Prosereflect::Paragraph.new({ 'type' => 'paragraph' })
      text = Prosereflect::Text.new({ 'type' => 'text', 'text' => 'Hello' })

      para.add_child(text)
      root.add_child(para)
      root
    end

    it 'returns self if type matches' do
      result = node.find_first('root')
      expect(result).to eq(node)
    end

    it 'finds a child node by type' do
      result = node.find_first('paragraph')
      expect(result).to be_a(Prosereflect::Paragraph)
    end

    it 'finds a nested node by type' do
      result = node.find_first('text')
      expect(result).to be_a(Prosereflect::Text)
    end

    it 'returns nil if no matching node is found' do
      result = node.find_first('nonexistent')
      expect(result).to be_nil
    end
  end

  describe '.create' do
    it 'creates a node with the specified type' do
      node = described_class.new('test_node')
      expect(node.type).to eq('test_node')
    end

    it 'creates a node with attributes' do
      attrs = { 'key' => 'value' }
      node = described_class.new('test_node', attrs)

      expect(node.type).to eq('test_node')
      expect(node.attrs).to eq(attrs)
    end

    it 'initializes with empty content' do
      node = described_class.new('test_node')
      expect(node.content).to eq([])
    end
  end

  describe '#find_all' do
    let(:node) do
      root = described_class.new({ 'type' => 'root' })

      para1 = Prosereflect::Paragraph.new({ 'type' => 'paragraph' })
      para1.add_child(Prosereflect::Text.new({ 'type' => 'text', 'text' => 'Text 1' }))

      para2 = Prosereflect::Paragraph.new({ 'type' => 'paragraph' })
      para2.add_child(Prosereflect::Text.new({ 'type' => 'text', 'text' => 'Text 2' }))

      root.add_child(para1)
      root.add_child(para2)
      root
    end

    it 'finds all nodes of a specific type' do
      paragraphs = node.find_all('paragraph')
      expect(paragraphs.size).to eq(2)
      expect(paragraphs).to all(be_a(Prosereflect::Paragraph))
    end

    it 'finds all nested nodes of a specific type' do
      texts = node.find_all('text')
      expect(texts.size).to eq(2)
      expect(texts).to all(be_a(Prosereflect::Text))
    end

    it 'returns empty array if no matching nodes are found' do
      result = node.find_all('nonexistent')
      expect(result).to eq([])
    end
  end

  describe '#find_children' do
    let(:node) do
      root = described_class.new({ 'type' => 'root' })

      root.add_child(Prosereflect::Paragraph.new({ 'type' => 'paragraph' }))
      root.add_child(Prosereflect::Table.new({ 'type' => 'table' }))
      root.add_child(Prosereflect::Paragraph.new({ 'type' => 'paragraph' }))

      root
    end

    it 'finds direct children of a specific type' do
      paragraphs = node.find_children(Prosereflect::Paragraph)
      expect(paragraphs.size).to eq(2)
      expect(paragraphs).to all(be_a(Prosereflect::Paragraph))
    end

    it 'returns empty array if no matching children are found' do
      result = node.find_children(String)
      expect(result).to eq([])
    end
  end

  describe '#text_content' do
    it 'returns empty string for node without content' do
      node = described_class.new({ 'type' => 'empty' })
      expect(node.text_content).to eq('')
    end

    it 'concatenates text content from all child nodes' do
      node = described_class.new({ 'type' => 'parent' })

      para = Prosereflect::Paragraph.new({ 'type' => 'paragraph' })
      para.add_child(Prosereflect::Text.new({ 'type' => 'text', 'text' => 'Hello' }))
      para.add_child(Prosereflect::HardBreak.new({ 'type' => 'hard_break' }))
      para.add_child(Prosereflect::Text.new({ 'type' => 'text', 'text' => 'World' }))

      node.add_child(para)

      expect(node.text_content).to eq("Hello\nWorld")
    end
  end
end
