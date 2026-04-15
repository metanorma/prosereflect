# frozen_string_literal: true

require "spec_helper"

RSpec.describe Prosereflect::Parser, ".round_trip" do
  # Helper to create a document from YAML
  def parse_doc(yaml_string)
    Prosereflect::Parser.parse_document(YAML.safe_load(yaml_string))
  end

  describe "Document serialization round-trip" do
    it "round-trips simple paragraph" do
      doc = parse_doc({
        "type" => "doc",
        "content" => [
          {
            "type" => "paragraph",
            "content" => [
              { "type" => "text", "text" => "Hello World" },
            ],
          },
        ],
      }.to_yaml)

      ruby_json = doc.to_h

      # Parse again and verify same structure
      doc2 = described_class.parse_document(ruby_json)
      expect(doc2.to_h).to eq(ruby_json)
    end

    it "round-trips document with formatted text" do
      doc = parse_doc({
        "type" => "doc",
        "content" => [
          {
            "type" => "paragraph",
            "content" => [
              {
                "type" => "text",
                "text" => "Hello",
                "marks" => [{ "type" => "bold" }],
              },
              {
                "type" => "text",
                "text" => " World",
              },
            ],
          },
        ],
      }.to_yaml)

      ruby_json = doc.to_h

      doc2 = described_class.parse_document(ruby_json)
      expect(doc2.to_h).to eq(ruby_json)
    end

    it "round-trips heading" do
      doc = parse_doc({
        "type" => "doc",
        "content" => [
          {
            "type" => "heading",
            "attrs" => { "level" => 1 },
            "content" => [
              { "type" => "text", "text" => "Title" },
            ],
          },
        ],
      }.to_yaml)

      ruby_json = doc.to_h

      doc2 = described_class.parse_document(ruby_json)
      expect(doc2.to_h).to eq(ruby_json)
    end

    it "round-trips blockquote" do
      doc = parse_doc({
        "type" => "doc",
        "content" => [
          {
            "type" => "blockquote",
            "content" => [
              {
                "type" => "paragraph",
                "content" => [
                  { "type" => "text", "text" => "Quote text" },
                ],
              },
            ],
          },
        ],
      }.to_yaml)

      ruby_json = doc.to_h

      doc2 = described_class.parse_document(ruby_json)
      expect(doc2.to_h).to eq(ruby_json)
    end

    it "round-trips bullet list" do
      doc = parse_doc({
        "type" => "doc",
        "content" => [
          {
            "type" => "bullet_list",
            "content" => [
              {
                "type" => "list_item",
                "content" => [
                  {
                    "type" => "paragraph",
                    "content" => [
                      { "type" => "text", "text" => "Item 1" },
                    ],
                  },
                ],
              },
            ],
          },
        ],
      }.to_yaml)

      ruby_json = doc.to_h

      doc2 = described_class.parse_document(ruby_json)
      expect(doc2.to_h).to eq(ruby_json)
    end

    it "round-trips ordered list" do
      doc = parse_doc({
        "type" => "doc",
        "content" => [
          {
            "type" => "ordered_list",
            "attrs" => { "order" => 1 },
            "content" => [
              {
                "type" => "list_item",
                "content" => [
                  {
                    "type" => "paragraph",
                    "content" => [
                      { "type" => "text", "text" => "Item 1" },
                    ],
                  },
                ],
              },
            ],
          },
        ],
      }.to_yaml)

      ruby_json = doc.to_h

      doc2 = described_class.parse_document(ruby_json)
      expect(doc2.to_h).to eq(ruby_json)
    end

    it "round-trips table" do
      doc = parse_doc({
        "type" => "doc",
        "content" => [
          {
            "type" => "table",
            "content" => [
              {
                "type" => "table_row",
                "content" => [
                  {
                    "type" => "table_cell",
                    "content" => [
                      {
                        "type" => "paragraph",
                        "content" => [
                          { "type" => "text", "text" => "Cell 1" },
                        ],
                      },
                    ],
                  },
                ],
              },
            ],
          },
        ],
      }.to_yaml)

      ruby_json = doc.to_h

      doc2 = described_class.parse_document(ruby_json)
      expect(doc2.to_h).to eq(ruby_json)
    end

    it "round-trips hard_break" do
      doc = parse_doc({
        "type" => "doc",
        "content" => [
          {
            "type" => "paragraph",
            "content" => [
              { "type" => "text", "text" => "Line 1" },
              { "type" => "hard_break" },
              { "type" => "text", "text" => "Line 2" },
            ],
          },
        ],
      }.to_yaml)

      ruby_json = doc.to_h

      doc2 = described_class.parse_document(ruby_json)
      expect(doc2.to_h).to eq(ruby_json)
    end

    it "round-trips horizontal rule" do
      doc = parse_doc({
        "type" => "doc",
        "content" => [
          { "type" => "horizontal_rule" },
        ],
      }.to_yaml)

      ruby_json = doc.to_h

      doc2 = described_class.parse_document(ruby_json)
      expect(doc2.to_h).to eq(ruby_json)
    end

    it "round-trips code block" do
      doc = parse_doc({
        "type" => "doc",
        "content" => [
          {
            "type" => "code_block",
            "attrs" => { "language" => "ruby" },
            "content" => [
              { "type" => "text", "text" => "puts 'hello'" },
            ],
          },
        ],
      }.to_yaml)

      ruby_json = doc.to_h

      doc2 = described_class.parse_document(ruby_json)
      # Verify structure is preserved - code block type and language
      code_block = doc2.find_first("code_block")
      expect(code_block).to be_a(Prosereflect::CodeBlock)
      expect(code_block.language).to eq("ruby")
    end
  end

  describe "Node equality" do
    it "same nodes are equal" do
      doc1 = parse_doc({
        "type" => "doc",
        "content" => [
          {
            "type" => "paragraph",
            "content" => [
              { "type" => "text", "text" => "Hello" },
            ],
          },
        ],
      }.to_yaml)

      doc2 = parse_doc({
        "type" => "doc",
        "content" => [
          {
            "type" => "paragraph",
            "content" => [
              { "type" => "text", "text" => "Hello" },
            ],
          },
        ],
      }.to_yaml)

      # Both should have same structure
      expect(doc1.to_h).to eq(doc2.to_h)
    end

    it "different nodes are not equal" do
      doc1 = parse_doc({
        "type" => "doc",
        "content" => [
          {
            "type" => "paragraph",
            "content" => [
              { "type" => "text", "text" => "Hello" },
            ],
          },
        ],
      }.to_yaml)

      doc2 = parse_doc({
        "type" => "doc",
        "content" => [
          {
            "type" => "paragraph",
            "content" => [
              { "type" => "text", "text" => "World" },
            ],
          },
        ],
      }.to_yaml)

      expect(doc1.to_h).not_to eq(doc2.to_h)
    end
  end

  describe "Text content extraction" do
    it "extracts text from simple document" do
      doc = parse_doc({
        "type" => "doc",
        "content" => [
          {
            "type" => "paragraph",
            "content" => [
              { "type" => "text", "text" => "Hello World" },
            ],
          },
        ],
      }.to_yaml)

      expect(doc.text_content).to eq("Hello World")
    end

    it "extracts text from nested structure" do
      doc = parse_doc({
        "type" => "doc",
        "content" => [
          {
            "type" => "blockquote",
            "content" => [
              {
                "type" => "paragraph",
                "content" => [
                  { "type" => "text", "text" => "Quote text" },
                ],
              },
            ],
          },
        ],
      }.to_yaml)

      expect(doc.text_content).to eq("Quote text")
    end

    it "extracts concatenated text from multiple paragraphs" do
      doc = parse_doc({
        "type" => "doc",
        "content" => [
          {
            "type" => "paragraph",
            "content" => [
              { "type" => "text", "text" => "First" },
            ],
          },
          {
            "type" => "paragraph",
            "content" => [
              { "type" => "text", "text" => "Second" },
            ],
          },
        ],
      }.to_yaml)

      # text_content returns text with newlines between block elements
      expect(doc.text_content).to include("First")
      expect(doc.text_content).to include("Second")
    end
  end

  describe "Mark preservation" do
    it "preserves bold mark" do
      doc = parse_doc({
        "type" => "doc",
        "content" => [
          {
            "type" => "paragraph",
            "content" => [
              {
                "type" => "text",
                "text" => "bold text",
                "marks" => [{ "type" => "bold" }],
              },
            ],
          },
        ],
      }.to_yaml)

      para = doc.find_first("paragraph")
      text = para.content.first
      expect(text.marks).to include("type" => "bold")
    end

    it "preserves italic mark" do
      doc = parse_doc({
        "type" => "doc",
        "content" => [
          {
            "type" => "paragraph",
            "content" => [
              {
                "type" => "text",
                "text" => "italic text",
                "marks" => [{ "type" => "italic" }],
              },
            ],
          },
        ],
      }.to_yaml)

      para = doc.find_first("paragraph")
      text = para.content.first
      expect(text.marks).to include("type" => "italic")
    end

    it "preserves multiple marks" do
      doc = parse_doc({
        "type" => "doc",
        "content" => [
          {
            "type" => "paragraph",
            "content" => [
              {
                "type" => "text",
                "text" => "bold and italic",
                "marks" => [
                  { "type" => "bold" },
                  { "type" => "italic" },
                ],
              },
            ],
          },
        ],
      }.to_yaml)

      para = doc.find_first("paragraph")
      text = para.content.first
      expect(text.marks).to include("type" => "bold")
      expect(text.marks).to include("type" => "italic")
    end

    it "preserves link mark with attrs" do
      doc = parse_doc({
        "type" => "doc",
        "content" => [
          {
            "type" => "paragraph",
            "content" => [
              {
                "type" => "text",
                "text" => "link text",
                "marks" => [
                  { "type" => "link", "attrs" => { "href" => "https://example.com" } },
                ],
              },
            ],
          },
        ],
      }.to_yaml)

      para = doc.find_first("paragraph")
      text = para.content.first
      expect(text.marks).to include("type" => "link", "attrs" => { "href" => "https://example.com" })
    end
  end
end
