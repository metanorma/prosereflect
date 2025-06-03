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
        marks: [Prosereflect::Mark::Bold.new]
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
    it 'creates a simple node' do
      node = described_class.create('test_node')

      expected = {
        'type' => 'test_node'
      }

      expect(node.to_h).to eq(expected)
    end

    it 'creates a node with attributes' do
      node = described_class.create('test_node', {
                                      'key' => 'value',
                                      'number' => 42,
                                      'flag' => true
                                    })

      expected = {
        'type' => 'test_node',
        'attrs' => {
          'key' => 'value',
          'number' => 42,
          'flag' => true
        }
      }

      expect(node.to_h).to eq(expected)
    end
  end

  describe 'node structure' do
    it 'creates a node with content' do
      node = described_class.create('parent')
      node.add_child(Prosereflect::Text.create('First child'))
      node.add_child(Prosereflect::Text.create('Second child'))

      expected = {
        'type' => 'parent',
        'content' => [
          {
            'type' => 'text',
            'text' => 'First child'
          },
          {
            'type' => 'text',
            'text' => 'Second child'
          }
        ]
      }

      expect(node.to_h).to eq(expected)
    end

    it 'creates a node with complex content' do
      node = described_class.create('root')

      # Add a paragraph with formatted text
      para = Prosereflect::Paragraph.create
      para.add_child(Prosereflect::Text.create('Bold', [Prosereflect::Mark::Bold.create]))
      para.add_child(Prosereflect::Text.create(' and '))
      para.add_child(Prosereflect::Text.create('italic', [Prosereflect::Mark::Italic.create]))
      node.add_child(para)

      # Add a list
      list = Prosereflect::BulletList.create
      list_item = Prosereflect::ListItem.create
      list_item.add_child(Prosereflect::Paragraph.create)
      list_item.content.first.add_child(Prosereflect::Text.create('List item'))
      list.add_child(list_item)
      node.add_child(list)

      expected = {
        'type' => 'root',
        'content' => [
          {
            'type' => 'paragraph',
            'content' => [
              {
                'type' => 'text',
                'text' => 'Bold',
                'marks' => [{ 'type' => 'bold' }]
              },
              {
                'type' => 'text',
                'text' => ' and '
              },
              {
                'type' => 'text',
                'text' => 'italic',
                'marks' => [{ 'type' => 'italic' }]
              }
            ]
          },
          {
            'type' => 'bullet_list',
            'attrs' => {
              'bullet_style' => nil
            },
            'content' => [
              {
                'type' => 'list_item',
                'content' => [
                  {
                    'type' => 'paragraph',
                    'content' => [
                      {
                        'type' => 'text',
                        'text' => 'List item'
                      }
                    ]
                  }
                ]
              }
            ]
          }
        ]
      }

      expect(node.to_h).to eq(expected)
    end
  end

  describe 'node operations' do
    describe '#add_child' do
      it 'adds a child node and returns it' do
        parent = described_class.create('parent')
        child = Prosereflect::Text.create('Child node')

        result = parent.add_child(child)
        expect(result).to eq(child)
        expect(parent.content).to eq([child])
      end

      it 'maintains child order' do
        parent = described_class.create('parent')
        first = Prosereflect::Text.create('First')
        second = Prosereflect::Text.create('Second')
        third = Prosereflect::Text.create('Third')

        parent.add_child(first)
        parent.add_child(second)
        parent.add_child(third)

        expect(parent.content).to eq([first, second, third])
        expect(parent.text_content).to eq('FirstSecondThird')
      end
    end

    describe '#find_first' do
      let(:node) do
        root = described_class.create('root')
        para = Prosereflect::Paragraph.create
        text = Prosereflect::Text.create('Hello')
        para.add_child(text)
        root.add_child(para)
        root
      end

      it 'finds nodes by type' do
        expect(node.find_first('root')).to eq(node)
        expect(node.find_first('paragraph')).to be_a(Prosereflect::Paragraph)
        expect(node.find_first('text')).to be_a(Prosereflect::Text)
        expect(node.find_first('nonexistent')).to be_nil
      end
    end

    describe '#find_all' do
      let(:node) do
        root = described_class.create('root')

        # First paragraph
        para1 = Prosereflect::Paragraph.create
        para1.add_child(Prosereflect::Text.create('First'))
        root.add_child(para1)

        # Second paragraph
        para2 = Prosereflect::Paragraph.create
        para2.add_child(Prosereflect::Text.create('Second'))
        root.add_child(para2)

        root
      end

      it 'finds all nodes of a type' do
        expect(node.find_all('paragraph').size).to eq(2)
        expect(node.find_all('text').size).to eq(2)
        expect(node.find_all('nonexistent')).to eq([])
      end
    end

    describe '#find_children' do
      let(:node) do
        root = described_class.create('root')
        root.add_child(Prosereflect::Paragraph.create)
        root.add_child(Prosereflect::Table.create)
        root.add_child(Prosereflect::Paragraph.create)
        root
      end

      it 'finds direct children by class' do
        paragraphs = node.find_children(Prosereflect::Paragraph)
        expect(paragraphs.size).to eq(2)
        expect(paragraphs).to all(be_a(Prosereflect::Paragraph))

        tables = node.find_children(Prosereflect::Table)
        expect(tables.size).to eq(1)
        expect(tables.first).to be_a(Prosereflect::Table)
      end
    end

    describe '#text_content' do
      it 'concatenates text from all children' do
        root = described_class.create('root')

        para = Prosereflect::Paragraph.create
        para.add_child(Prosereflect::Text.create('Hello'))
        para.add_child(Prosereflect::HardBreak.create)
        para.add_child(Prosereflect::Text.create('World'))
        root.add_child(para)

        expect(root.text_content).to eq("Hello\nWorld")
      end

      it 'returns empty string for empty node' do
        node = described_class.create('empty')
        expect(node.text_content).to eq('')
      end
    end
  end

  describe 'serialization' do
    it 'serializes a node with all properties' do
      node = described_class.create('test_node', {
                                      'key' => 'value',
                                      'number' => 42
                                    })

      text = Prosereflect::Text.create('Content', [
                                         Prosereflect::Mark::Bold.create,
                                         Prosereflect::Mark::Link.create({ 'href' => 'https://example.com' })
                                       ])

      node.add_child(text)

      expected = {
        'type' => 'test_node',
        'attrs' => {
          'key' => 'value',
          'number' => 42
        },
        'content' => [
          {
            'type' => 'text',
            'text' => 'Content',
            'marks' => [
              { 'type' => 'bold' },
              {
                'type' => 'link',
                'attrs' => {
                  'href' => 'https://example.com'
                }
              }
            ]
          }
        ]
      }

      expect(node.to_h).to eq(expected)
    end

    it 'omits optional properties when empty' do
      node = described_class.create('test_node')

      expected = {
        'type' => 'test_node'
      }

      expect(node.to_h).to eq(expected)
    end
  end
end
