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
    it 'creates an empty document' do
      doc = described_class.new
      expect(doc).to be_a(described_class)
      expect(doc.type).to eq('doc')
      expect(doc.content).to be_nil
    end

    it 'creates a document with attributes' do
      attrs = [Prosereflect::Attribute::Id.new(id: '1')]
      doc = described_class.new(attrs: attrs)
      expect(doc.attrs).to eq(attrs)
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
end
