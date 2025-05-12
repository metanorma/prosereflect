# frozen_string_literal: true

RSpec.shared_examples 'a parsable format' do |format|
  it "parses #{format} content correctly" do
    document = case format
               when :yaml
                 Prosemirror::Parser.parse_document(YAML.safe_load(file_content))
               when :json
                 Prosemirror::Parser.parse_document(JSON.parse(file_content))
               end

    expect(document).to be_a(Prosemirror::Document)
    expect(document.content).not_to be_empty
  end

  it "maintains structure after #{format} round-trip" do
    # Parse the original content
    original_data = case format
                    when :yaml
                      YAML.safe_load(file_content)
                    when :json
                      JSON.parse(file_content)
                    end

    # Create a document from the data
    document = Prosemirror::Parser.parse_document(original_data)

    # Convert back to the original format
    round_trip_data = case format
                      when :yaml
                        YAML.safe_load(document.to_yaml)
                      when :json
                        JSON.parse(document.to_json)
                      end

    # Compare the structures
    case format
    when :yaml
      expect(round_trip_data).to be_equivalent_yaml(original_data)
    when :json
      expect(round_trip_data).to be_equivalent_json(original_data)
    end
  end
end

RSpec.shared_examples 'a document with tables' do
  it 'contains at least one table' do
    document = case file_content
               when String
                 if file_content.strip.start_with?('{')
                   Prosemirror::Parser.parse_document(JSON.parse(file_content))
                 else
                   Prosemirror::Parser.parse_document(YAML.safe_load(file_content))
                 end
               else
                 Prosemirror::Parser.parse_document(file_content)
               end

    expect(document.tables.size).to be > 0
  end

  it 'has tables with rows and cells' do
    document = case file_content
               when String
                 if file_content.strip.start_with?('{')
                   Prosemirror::Parser.parse_document(JSON.parse(file_content))
                 else
                   Prosemirror::Parser.parse_document(YAML.safe_load(file_content))
                 end
               else
                 Prosemirror::Parser.parse_document(file_content)
               end

    table = document.tables.first
    expect(table.rows.size).to be > 0
    expect(table.rows.first.cells.size).to be > 0
  end
end

RSpec.shared_examples 'document traversal' do
  it 'can find nodes by type' do
    document = case file_content
               when String
                 if file_content.strip.start_with?('{')
                   Prosemirror::Parser.parse_document(JSON.parse(file_content))
                 else
                   Prosemirror::Parser.parse_document(YAML.safe_load(file_content))
                 end
               else
                 Prosemirror::Parser.parse_document(file_content)
               end

    expect(document.find_all('table').size).to be > 0
    expect(document.find_all('paragraph').size).to be >= 0
    expect(document.find_all('text').size).to be > 0
  end
end

RSpec.shared_examples 'text content extraction' do
  it 'extracts text content from nodes' do
    document = case file_content
               when String
                 if file_content.strip.start_with?('{')
                   Prosemirror::Parser.parse_document(JSON.parse(file_content))
                 else
                   Prosemirror::Parser.parse_document(YAML.safe_load(file_content))
                 end
               else
                 Prosemirror::Parser.parse_document(file_content)
               end

    # Get text from the first paragraph or table cell that contains text
    text_container = document.find_first('paragraph') || document.find_first('table_cell')

    if text_container
      expect(text_container.text_content).to be_a(String)
      expect(text_container.text_content).not_to be_empty if text_container.find_first('text')
    end
  end
end

RSpec.shared_examples 'document creation' do
  it 'creates an empty document' do
    document = Prosemirror::Document.create
    expect(document).to be_a(Prosemirror::Document)
    expect(document.type).to eq('doc')
    expect(document.content).to eq([])
  end

  it 'creates a document with attributes' do
    attrs = { 'version' => '1.0' }
    document = Prosemirror::Document.create(attrs)
    expect(document.attrs).to eq(attrs)
  end

  it 'adds paragraphs to a document' do
    document = Prosemirror::Document.create
    paragraph = document.add_paragraph('Test paragraph')

    expect(document.content.size).to eq(1)
    expect(paragraph).to be_a(Prosemirror::Paragraph)
    expect(paragraph.text_content).to eq('Test paragraph')
  end

  it 'adds tables to a document' do
    document = Prosemirror::Document.create
    table = document.add_table

    expect(document.content.size).to eq(1)
    expect(table).to be_a(Prosemirror::Table)
  end
end

# Helper for parsing any format of content
RSpec.shared_examples 'format parsing' do
  let(:document) do
    case file_content
    when String
      if file_content.strip.start_with?('{')
        Prosemirror::Parser.parse_document(JSON.parse(file_content))
      else
        Prosemirror::Parser.parse_document(YAML.safe_load(file_content))
      end
    else
      Prosemirror::Parser.parse_document(file_content)
    end
  end
end

RSpec.shared_examples 'format round-trip' do |format|
  it "maintains document structure after #{format} round-trip" do
    # Create a rich document
    document = Prosemirror::Document.create

    # Add paragraph with formatted text
    para = document.add_paragraph('Plain text')
    para.add_text(' bold text', [{ 'type' => 'bold' }])
    para.add_hard_break
    para.add_text('After line break', [{ 'type' => 'italic' }])

    # Add a table
    table = document.add_table
    table.add_header(['Header 1', 'Header 2', 'Header 3'])
    table.add_row(%w[R1C1 R1C2 R1C3])
    table.add_row(%w[R2C1 R2C2 R2C3])

    # Add another paragraph
    document.add_paragraph('Concluding paragraph')

    # Convert to specified format and back
    parsed_doc = round_trip_conversion(document, format)

    # Verify structure is maintained
    expect(parsed_doc.paragraphs.size).to eq(document.paragraphs.size)
    expect(parsed_doc.tables.size).to eq(document.tables.size)
    expect(parsed_doc.find_all('hard_break').size).to eq(document.find_all('hard_break').size)

    # Verify table structure
    table_in_parsed = parsed_doc.first_table
    expect(table_in_parsed.rows.size).to eq(document.first_table.rows.size)
    expect(table_in_parsed.header_row.cells.size).to eq(document.first_table.header_row.cells.size)
  end

  def round_trip_conversion(doc, format)
    case format
    when :yaml
      yaml = doc.to_yaml
      parsed = Prosemirror::Parser.parse_document(YAML.safe_load(yaml))
      # Compare structures
      expect(YAML.safe_load(parsed.to_yaml)).to be_equivalent_yaml(YAML.safe_load(doc.to_yaml))
      parsed
    when :json
      json = doc.to_json
      parsed = Prosemirror::Parser.parse_document(JSON.parse(json))
      # Compare structures
      expect(JSON.parse(parsed.to_json)).to be_equivalent_json(JSON.parse(doc.to_json))
      parsed
    end
  end
end
