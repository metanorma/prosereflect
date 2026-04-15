# frozen_string_literal: true

require "spec_helper"
require "yaml"

RSpec.describe "TransformEquivalence" do # rubocop:disable RSpec/DescribeClass
  def parse_doc(yaml_string)
    Prosereflect::Parser.parse_document(YAML.safe_load(yaml_string))
  end

  def parse_hash(hash)
    Prosereflect::Parser.parse_document(hash)
  end

  describe "fixture round-trips" do
    Dir[File.expand_path("../../fixtures/documents/*.yaml", __dir__)].each do |path|
      it "round-trips #{File.basename(path)}" do
        data = YAML.safe_load_file(path)
        doc = Prosereflect::Parser.parse_document(data)
        expect(doc.to_h).to eq(data)
      end
    end
  end

  describe "node type round-trips" do
    it "round-trips paragraph with bold text" do
      doc = parse_hash({
                         "type" => "doc",
                         "content" => [
                           {
                             "type" => "paragraph",
                             "content" => [
                               { "type" => "text", "text" => "bold", "marks" => [{ "type" => "bold" }] },
                               { "type" => "text", "text" => " and " },
                               { "type" => "text", "text" => "italic", "marks" => [{ "type" => "italic" }] },
                             ],
                           },
                         ],
                       })
      expect(parse_hash(doc.to_h).to_h).to eq(doc.to_h)
    end

    it "round-trips heading with level" do
      doc = parse_hash({
                         "type" => "doc",
                         "content" => [
                           { "type" => "heading", "attrs" => { "level" => 2 }, "content" => [{ "type" => "text", "text" => "Title" }] },
                         ],
                       })
      expect(parse_hash(doc.to_h).to_h).to eq(doc.to_h)
    end

    it "round-trips link with href" do
      doc = parse_hash({
                         "type" => "doc",
                         "content" => [
                           {
                             "type" => "paragraph",
                             "content" => [
                               { "type" => "text", "text" => "click here", "marks" => [{ "type" => "link", "attrs" => { "href" => "https://example.com" } }] },
                             ],
                           },
                         ],
                       })
      expect(parse_hash(doc.to_h).to_h).to eq(doc.to_h)
    end

    it "round-trips nested blockquote" do
      doc = parse_hash({
                         "type" => "doc",
                         "content" => [
                           {
                             "type" => "blockquote",
                             "content" => [
                               {
                                 "type" => "paragraph",
                                 "content" => [{ "type" => "text", "text" => "Nested quote" }],
                               },
                             ],
                           },
                         ],
                       })
      expect(parse_hash(doc.to_h).to_h).to eq(doc.to_h)
    end

    it "round-trips table with headers and cells" do
      doc = parse_hash({
                         "type" => "doc",
                         "content" => [
                           {
                             "type" => "table",
                             "content" => [
                               {
                                 "type" => "table_row",
                                 "content" => [
                                   { "type" => "table_header", "content" => [{ "type" => "paragraph", "content" => [{ "type" => "text", "text" => "H" }] }] },
                                 ],
                               },
                               {
                                 "type" => "table_row",
                                 "content" => [
                                   { "type" => "table_cell", "content" => [{ "type" => "paragraph", "content" => [{ "type" => "text", "text" => "C" }] }] },
                                 ],
                               },
                             ],
                           },
                         ],
                       })
      expect(parse_hash(doc.to_h).to_h).to eq(doc.to_h)
    end
  end

  describe "transform operations consistency" do
    it "split and join are inverse for simple paragraphs" do
      doc = parse_hash({
                         "type" => "doc",
                         "content" => [
                           { "type" => "paragraph", "content" => [{ "type" => "text", "text" => "Hello World" }] },
                         ],
                       })
      # Split at position 5 creates two nodes
      tx = Prosereflect::Transform::Transform.new(doc)
      tx.split(5)
      expect(tx.size).to eq(1)
    end

    it "delete and insert are consistent" do
      doc = parse_hash({
                         "type" => "doc",
                         "content" => [
                           { "type" => "paragraph", "content" => [{ "type" => "text", "text" => "abc" }] },
                         ],
                       })
      tx = Prosereflect::Transform::Transform.new(doc)
      tx.delete(2, 4)
      expect(tx.size).to eq(1)
    end

    it "replace step produces correct mapping" do
      doc = parse_hash({
                         "type" => "doc",
                         "content" => [
                           { "type" => "paragraph", "content" => [{ "type" => "text", "text" => "hello" }] },
                         ],
                       })
      tx = Prosereflect::Transform::Transform.new(doc)
      tx.replace(2, 5, Prosereflect::Transform::Slice.empty)
      expect(tx.size).to eq(1)
      expect(tx.maps.length).to eq(1)
    end

    it "add_mark and remove_mark steps" do
      doc = parse_hash({
                         "type" => "doc",
                         "content" => [
                           { "type" => "paragraph", "content" => [{ "type" => "text", "text" => "hello" }] },
                         ],
                       })
      tx = Prosereflect::Transform::Transform.new(doc)
      mark = Prosereflect::Mark::Bold.new
      tx.add_mark(0, 5, mark)
      tx.remove_mark(0, 5, mark)
      expect(tx.size).to eq(2)
    end
  end

  describe "node_size consistency" do
    it "document with single paragraph" do
      doc = parse_hash({
                         "type" => "doc",
                         "content" => [
                           { "type" => "paragraph", "content" => [{ "type" => "text", "text" => "hi" }] },
                         ],
                       })
      # doc=1 + para=1 + text("hi")=3 = 5
      expect(doc.node_size).to eq(5)
    end

    it "document with multiple paragraphs" do
      doc = parse_hash({
                         "type" => "doc",
                         "content" => [
                           { "type" => "paragraph", "content" => [{ "type" => "text", "text" => "ab" }] },
                           { "type" => "paragraph", "content" => [{ "type" => "text", "text" => "cd" }] },
                         ],
                       })
      # doc=1 + (para=1+text=3) + (para=1+text=3) = 9
      expect(doc.node_size).to eq(9)
    end

    it "text node_size equals length + 1" do
      text = Prosereflect::Text.new(text: "hello")
      expect(text.node_size).to eq(6)
      expect(text.node_size).to eq(text.text.length + 1)
    end

    it "empty text node_size is 1" do
      text = Prosereflect::Text.new(text: "")
      expect(text.node_size).to eq(1)
    end
  end

  describe "resolve consistency" do
    it "resolve(0) returns depth 0" do
      doc = parse_hash({
                         "type" => "doc",
                         "content" => [
                           { "type" => "paragraph", "content" => [{ "type" => "text", "text" => "hi" }] },
                         ],
                       })
      r = doc.resolve(0)
      expect(r.depth).to eq(0)
      expect(r.parent).to be_a(Prosereflect::Document)
    end

    it "resolve at paragraph boundary" do
      doc = parse_hash({
                         "type" => "doc",
                         "content" => [
                           { "type" => "paragraph", "content" => [{ "type" => "text", "text" => "hi" }] },
                           { "type" => "paragraph", "content" => [{ "type" => "text", "text" => "there" }] },
                         ],
                       })
      # Position 5 = after first paragraph (1+1+3=5), before second paragraph
      r = doc.resolve(5)
      expect(r.depth).to eq(1)
      expect(r.parent).to be_a(Prosereflect::Paragraph)
    end

    it "resolve at start of document" do
      doc = parse_hash({
                         "type" => "doc",
                         "content" => [
                           { "type" => "paragraph", "content" => [{ "type" => "text", "text" => "hi" }] },
                         ],
                       })
      r = doc.resolve(0)
      expect(r.depth).to eq(0)
      expect(r.pos).to eq(0)
    end

    it "resolve at end of document" do
      doc = parse_hash({
                         "type" => "doc",
                         "content" => [
                           { "type" => "paragraph", "content" => [{ "type" => "text", "text" => "hi" }] },
                         ],
                       })
      # doc_size = 1+1+3 = 5
      r = doc.resolve(5)
      expect(r.depth).to eq(0)
      expect(r.pos).to eq(5)
    end

    it "resolve at text position" do
      doc = parse_hash({
                         "type" => "doc",
                         "content" => [
                           { "type" => "paragraph", "content" => [{ "type" => "text", "text" => "abc" }] },
                         ],
                       })
      # pos 3 = inside text "abc" at character "c"
      r = doc.resolve(3)
      expect(r.depth).to eq(2)
      expect(r.node(1)).to be_a(Prosereflect::Paragraph)
    end

    it "resolved position index is correct" do
      doc = parse_hash({
                         "type" => "doc",
                         "content" => [
                           { "type" => "paragraph", "content" => [{ "type" => "text", "text" => "ab" }] },
                           { "type" => "paragraph", "content" => [{ "type" => "text", "text" => "cd" }] },
                         ],
                       })
      # pos 0 = before doc content, index 0
      r = doc.resolve(0)
      expect(r.index(0)).to eq(0)
    end

    it "resolved position parent_offset is correct" do
      doc = parse_hash({
                         "type" => "doc",
                         "content" => [
                           { "type" => "paragraph", "content" => [{ "type" => "text", "text" => "hi" }] },
                         ],
                       })
      r = doc.resolve(3)
      expect(r.parent_offset).to be >= 0
    end
  end

  describe "schema equivalence" do
    def basic_schema
      Prosereflect::Schema.new(
        nodes_spec: {
          "doc" => { content: "block+" },
          "paragraph" => { content: "inline*", group: "block" },
          "heading" => { content: "inline*", group: "block", attrs: { "level" => { "default" => 1 } } },
          "text" => { group: "inline" },
        },
        marks_spec: {
          "bold" => {},
          "italic" => {},
          "link" => { attrs: { "href" => {} } },
        },
      )
    end

    it "schema has correct node types" do
      schema = basic_schema
      expect(schema.node_type("doc")).to be_a(Prosereflect::Schema::NodeType)
      expect(schema.node_type("paragraph")).to be_a(Prosereflect::Schema::NodeType)
      expect(schema.node_type("text")).to be_a(Prosereflect::Schema::NodeType)
    end

    it "schema has correct mark types" do
      schema = basic_schema
      expect(schema.mark_type("bold")).to be_a(Prosereflect::Schema::MarkType)
      expect(schema.mark_type("italic")).to be_a(Prosereflect::Schema::MarkType)
    end

    it "schema raises for unknown node type" do
      schema = basic_schema
      expect { schema.node_type("unknown") }.to raise_error(Prosereflect::SchemaErrors::ValidationError)
    end

    it "schema raises for unknown mark type" do
      schema = basic_schema
      expect { schema.mark_type("unknown") }.to raise_error(Prosereflect::SchemaErrors::ValidationError)
    end

    it "schema top_node_type returns doc" do
      schema = basic_schema
      expect(schema.top_node_type.name).to eq("doc")
    end

    it "schema requires doc and text node types" do
      expect do
        Prosereflect::Schema.new(
          nodes_spec: { "paragraph" => { content: "inline*" } },
          marks_spec: {},
        )
      end.to raise_error(Prosereflect::SchemaErrors::ValidationError)
    end

    it "schema mark type create returns a mark" do
      schema = basic_schema
      mark = schema.mark_type("bold").create
      expect(mark).to be_a(Prosereflect::Schema::Mark)
    end

    it "schema mark with attributes" do
      schema = basic_schema
      mark = schema.mark_type("link").create("href" => "https://example.com")
      expect(mark.attrs).to include("href" => "https://example.com")
    end
  end

  describe "HTML round-trip equivalence" do
    it "round-trips simple HTML through parse" do
      html = "<p>Hello world</p>"
      doc = Prosereflect::Input::Html.parse(html)
      para = doc.find_first("paragraph")
      expect(para).to be_a(Prosereflect::Paragraph)
      expect(para.text_content).to eq("Hello world")
    end

    it "round-trips formatted HTML through parse" do
      html = "<p><strong>bold</strong> and <em>italic</em></p>"
      doc = Prosereflect::Input::Html.parse(html)
      para = doc.find_first("paragraph")
      expect(para).to be_a(Prosereflect::Paragraph)
      expect(para.text_content).to include("bold")
      expect(para.text_content).to include("italic")
    end

    it "round-trips heading HTML" do
      html = "<h2>Title</h2>"
      doc = Prosereflect::Input::Html.parse(html)
      expect(doc.find_first("heading")).to be_a(Prosereflect::Heading)
    end

    it "round-trips list HTML" do
      html = "<ul><li>one</li><li>two</li></ul>"
      doc = Prosereflect::Input::Html.parse(html)
      expect(doc.find_first("bullet_list")).to be_a(Prosereflect::BulletList)
    end
  end

  describe "node type round-trips with attrs" do
    it "round-trips heading with all levels" do
      (1..6).each do |level|
        doc = parse_hash({
                           "type" => "doc",
                           "content" => [
                             { "type" => "heading", "attrs" => { "level" => level },
                               "content" => [{ "type" => "text", "text" => "H#{level}" }] },
                           ],
                         })
        expect(parse_hash(doc.to_h).to_h).to eq(doc.to_h)
      end
    end

    it "round-trips bullet list" do
      doc = parse_hash({
                         "type" => "doc",
                         "content" => [
                           {
                             "type" => "bullet_list",
                             "content" => [
                               { "type" => "list_item", "content" => [{ "type" => "paragraph", "content" => [{ "type" => "text", "text" => "item" }] }] },
                             ],
                           },
                         ],
                       })
      expect(parse_hash(doc.to_h).to_h).to eq(doc.to_h)
    end

    it "round-trips ordered list" do
      doc = parse_hash({
                         "type" => "doc",
                         "content" => [
                           {
                             "type" => "ordered_list",
                             "attrs" => { "start" => 1 },
                             "content" => [
                               { "type" => "list_item", "content" => [{ "type" => "paragraph", "content" => [{ "type" => "text", "text" => "first" }] }] },
                             ],
                           },
                         ],
                       })
      expect(parse_hash(doc.to_h).to_h).to eq(doc.to_h)
    end

    it "round-trips hard_break" do
      doc = parse_hash({
                         "type" => "doc",
                         "content" => [
                           { "type" => "paragraph", "content" => [
                             { "type" => "text", "text" => "before" },
                             { "type" => "hard_break" },
                             { "type" => "text", "text" => "after" },
                           ] },
                         ],
                       })
      expect(parse_hash(doc.to_h).to_h).to eq(doc.to_h)
    end

    it "round-trips horizontal_rule" do
      doc = parse_hash({
                         "type" => "doc",
                         "content" => [
                           { "type" => "paragraph", "content" => [{ "type" => "text", "text" => "above" }] },
                           { "type" => "horizontal_rule" },
                           { "type" => "paragraph", "content" => [{ "type" => "text", "text" => "below" }] },
                         ],
                       })
      expect(parse_hash(doc.to_h).to_h).to eq(doc.to_h)
    end

    it "round-trips code_block" do
      doc = parse_hash({
                         "type" => "doc",
                         "content" => [
                           { "type" => "code_block_wrapper", "content" => [
                             { "type" => "code_block", "attrs" => { "language" => "ruby", "content" => "puts 'hi'" } },
                           ] },
                         ],
                       })
      expect(parse_hash(doc.to_h).to_h).to eq(doc.to_h)
    end

    it "round-trips user mention" do
      doc = parse_hash({
                         "type" => "doc",
                         "content" => [
                           { "type" => "paragraph", "content" => [
                             { "type" => "text", "text" => "hello " },
                             { "type" => "user", "attrs" => { "id" => "user-123" } },
                           ] },
                         ],
                       })
      expect(parse_hash(doc.to_h).to_h).to eq(doc.to_h)
    end
  end
end
