# frozen_string_literal: true

require "spec_helper"

RSpec.describe "mark steps" do # rubocop:disable RSpec/DescribeClass
  describe Prosereflect::Transform::AddMarkStep do
    let(:bold) { Prosereflect::Mark::Bold.new }

    def doc_with_text(str)
      Prosereflect::Parser.parse_document(
        "type" => "doc",
        "content" => [{ "type" => "paragraph", "content" => [{ "type" => "text", "text" => str }] }],
      )
    end

    it "adds a mark over a partial text range (was a silent no-op)" do
      doc = doc_with_text("Hello") # "Hello" spans doc [2,7); mark "ell" = [3,6)
      result = described_class.new(3, 6, bold).apply(doc)

      expect(result).to be_ok
      pieces = result.doc.content[0].content
      expect(pieces.map(&:text)).to eq(%w[H ell o])
      expect(pieces.map { |t| (t.raw_marks || []).map(&:type) }).to eq([[], %w[bold], []])
    end

    it "fails on inverted positions" do
      expect(described_class.new(6, 3, bold).apply(doc_with_text("Hello"))).not_to be_ok
    end

    it "fails when the range end exceeds the document size" do
      doc = doc_with_text("Hello") # doc.node_size == 7
      expect(described_class.new(3, doc.node_size + 1, bold).apply(doc)).not_to be_ok
    end

    it "round-trips through JSON via Mark.from_h" do
      step = described_class.new(3, 6, bold)
      json = step.to_json
      expect(json).to include("from" => 3, "to" => 6)

      restored = described_class.from_json(nil, json)
      expect(restored.from).to eq(3)
      expect(restored.to).to eq(6)
      expect(restored.mark.type).to eq("bold")
    end

    it "does not mark a block leaf in the range" do
      # doc @0; paragraph "a" token @1 (spans [1,3)); horizontal_rule token @3 (spans [3,4))
      doc = Prosereflect::Parser.parse_document(
        "type" => "doc",
        "content" => [
          { "type" => "paragraph", "content" => [{ "type" => "text", "text" => "a" }] },
          { "type" => "horizontal_rule" },
        ],
      )
      result = described_class.new(1, 4, bold).apply(doc)

      expect(result).to be_ok
      hr = result.doc.content[1]
      expect(hr.type).to eq("horizontal_rule")
      expect(hr.raw_marks || []).to eq([])
    end

    it "preserves a heading's typed attributes when marking its text" do
      # doc @0; heading token @1 (attrs level:2); "Hi" spans [2,4)
      doc = Prosereflect::Parser.parse_document(
        "type" => "doc",
        "content" => [{ "type" => "heading", "attrs" => { "level" => 2 },
                        "content" => [{ "type" => "text", "text" => "Hi" }] }],
      )
      result = described_class.new(2, 4, bold).apply(doc)

      expect(result).to be_ok
      expect(result.doc.content[0].to_h["attrs"]).to eq({ "level" => 2 })
    end
  end

  describe Prosereflect::Transform::RemoveMarkStep do
    let(:bold) { Prosereflect::Mark::Bold.new }

    def bold_doc
      Prosereflect::Parser.parse_document(
        "type" => "doc",
        "content" => [{ "type" => "paragraph",
                        "content" => [{ "type" => "text", "text" => "Hello",
                                        "marks" => [{ "type" => "bold" }] }] }],
      )
    end

    it "removes a mark over a partial range (was always a NoMethodError failure)" do
      doc = bold_doc # bold "Hello" [2,7); unmark "ell" = [3,6)
      result = described_class.new(3, 6, bold).apply(doc)

      expect(result).to be_ok
      pieces = result.doc.content[0].content
      expect(pieces.map(&:text)).to eq(%w[H ell o])
      expect(pieces.map { |t| (t.raw_marks || []).map(&:type) }).to eq([%w[bold], [], %w[bold]])
    end

    it "leaves a same-type mark with different attrs untouched" do
      doc = Prosereflect::Parser.parse_document(
        "type" => "doc",
        "content" => [{ "type" => "paragraph",
                        "content" => [{ "type" => "text", "text" => "hi",
                                        "marks" => [{ "type" => "link", "attrs" => { "href" => "b" } }] }] }],
      )
      link_a = Prosereflect::Mark::Link.new(attrs: { "href" => "a" })
      result = described_class.new(2, 4, link_a).apply(doc)

      expect(result.doc.content[0].content.first.raw_marks.map(&:type)).to eq(%w[link])
    end
  end

  describe Prosereflect::Transform::AddNodeMarkStep do
    let(:bold) { Prosereflect::Mark::Bold.new }

    # doc > [ paragraph(text "a"), paragraph(text "b") ]
    # doc @0; para1 token @1 (node_size 2, spans [1,3)); para2 token @3.
    def two_paras
      Prosereflect::Parser.parse_document(
        "type" => "doc",
        "content" => [
          { "type" => "paragraph", "content" => [{ "type" => "text", "text" => "a" }] },
          { "type" => "paragraph", "content" => [{ "type" => "text", "text" => "b" }] },
        ],
      )
    end

    it "marks a nested node, not just a top-level child" do
      doc = two_paras
      result = described_class.new(3, bold).apply(doc)

      expect(result).to be_ok
      expect(result.doc.content[1].raw_marks.map(&:type)).to eq(%w[bold])
      expect(result.doc.content[0].raw_marks).to be_nil
      expect(result.doc.node_size).to eq(doc.node_size)
    end

    it "preserves an image's typed attributes when node-marking it" do
      # doc @0; paragraph token @1; image token @2
      doc = Prosereflect::Parser.parse_document(
        "type" => "doc",
        "content" => [{ "type" => "paragraph",
                        "content" => [{ "type" => "image", "attrs" => { "src" => "s", "alt" => "a" } }] }],
      )
      result = described_class.new(2, bold).apply(doc)

      expect(result).to be_ok
      image = result.doc.content[0].content[0]
      expect(image.to_h["attrs"]).to eq({ "src" => "s", "alt" => "a" })
      expect(image.raw_marks.map(&:type)).to eq(%w[bold])
    end
  end

  describe Prosereflect::Transform::RemoveNodeMarkStep do
    let(:bold) { Prosereflect::Mark::Bold.new }

    it "removes a mark from a nested node" do
      doc = Prosereflect::Parser.parse_document(
        "type" => "doc",
        "content" => [
          { "type" => "paragraph", "content" => [{ "type" => "text", "text" => "a" }] },
          { "type" => "paragraph", "marks" => [{ "type" => "bold" }],
            "content" => [{ "type" => "text", "text" => "b" }] },
        ],
      )
      result = described_class.new(3, bold).apply(doc)

      expect(result).to be_ok
      expect(result.doc.content[1].raw_marks).to eq([])
    end
  end
end
