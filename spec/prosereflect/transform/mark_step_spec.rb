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

    it "rejects a non-integer position at parse time" do
      expect do
        described_class.from_json(nil, { "from" => "3", "to" => 6, "mark" => { "type" => "bold" } })
      end.to raise_error(ArgumentError, /from/)
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

    it "rejects a non-integer position at parse time" do
      expect do
        described_class.from_json(nil, { "from" => 3, "to" => "6", "mark" => { "type" => "bold" } })
      end.to raise_error(ArgumentError, /to/)
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

    it "fails at a position one past the last node token" do
      doc = two_paras
      expect(described_class.new(doc.node_size, bold).apply(doc)).not_to be_ok
      expect(described_class.new(doc.node_size - 1, bold).apply(doc)).to be_ok
    end

    it "leaves no stray range key in its JSON" do
      json = described_class.new(3, bold).to_json

      expect(json).to eq({ "stepType" => "addNodeMark", "pos" => 3, "mark" => { "type" => "bold" } })
    end

    it "rejects a non-integer position at parse time" do
      expect do
        described_class.from_json(nil, { "pos" => "3", "mark" => { "type" => "bold" } })
      end.to raise_error(ArgumentError, /pos/)
    end

    describe "#invert" do
      let(:old_link) { Prosereflect::Mark::Link.new(attrs: { "href" => "old" }) }
      let(:new_link) { Prosereflect::Mark::Link.new(attrs: { "href" => "new" }) }

      # doc @0; paragraph token @1; text "hello" spans [2,7).
      def linked_doc
        Prosereflect::Parser.parse_document(
          "type" => "doc",
          "content" => [{ "type" => "paragraph",
                          "content" => [{ "type" => "text", "text" => "hello",
                                          "marks" => [{ "type" => "link",
                                                        "attrs" => { "href" => "old" } }] }] }],
        )
      end

      def text_marks(doc)
        doc.content[0].content[0].raw_marks
      end

      it "restores the href a same-type mark replaced" do
        doc = linked_doc
        step = described_class.new(2, new_link)
        applied = step.apply(doc).doc
        restored = step.invert(doc).apply(applied).doc

        expect(restored.to_h).to eq(doc.to_h)
        expect(text_marks(restored).map(&:attrs)).to eq([{ "href" => "old" }])
      end

      it "removes a mark that was genuinely added" do
        doc = linked_doc
        step = described_class.new(2, Prosereflect::Mark::Bold.new)
        applied = step.apply(doc).doc
        restored = step.invert(doc).apply(applied).doc

        expect(text_marks(restored).map(&:type)).to eq(%w[link])
      end

      it "inverts re-adding an identical mark to a no-op" do
        doc = linked_doc
        step = described_class.new(2, old_link)
        applied = step.apply(doc).doc
        restored = step.invert(doc).apply(applied).doc

        expect(text_marks(restored).map(&:attrs)).to eq([{ "href" => "old" }])
      end

      it "inverts to a removal when no node sits at the position" do
        doc = linked_doc
        # Position 4 lands inside the text node's characters, on no node token.
        expect(described_class.new(4, bold).invert(doc))
          .to be_a(Prosereflect::Transform::RemoveNodeMarkStep)
      end
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

    it "fails at a position one past the last node token" do
      doc = Prosereflect::Parser.parse_document(
        "type" => "doc",
        "content" => [{ "type" => "paragraph", "content" => [{ "type" => "text", "text" => "a" }] }],
      )
      expect(described_class.new(doc.node_size, bold).apply(doc)).not_to be_ok
      expect(described_class.new(doc.node_size - 1, bold).apply(doc)).to be_ok
    end

    it "leaves no stray range key in its JSON" do
      json = described_class.new(3, bold).to_json

      expect(json).to eq({ "stepType" => "removeNodeMark", "pos" => 3, "mark" => { "type" => "bold" } })
    end

    it "rejects a non-integer position at parse time" do
      expect do
        described_class.from_json(nil, { "pos" => "3", "mark" => { "type" => "bold" } })
      end.to raise_error(ArgumentError, /pos/)
    end

    describe "#invert" do
      # doc @0; paragraph token @1; text "a" spans [2,3).
      def marked_doc
        Prosereflect::Parser.parse_document(
          "type" => "doc",
          "content" => [{ "type" => "paragraph", "marks" => [{ "type" => "bold" }],
                          "content" => [{ "type" => "text", "text" => "a" }] }],
        )
      end

      it "restores a mark that was genuinely removed" do
        doc = marked_doc
        step = described_class.new(1, bold)
        applied = step.apply(doc).doc
        restored = step.invert(doc).apply(applied).doc

        expect(restored.content[0].raw_marks.map(&:type)).to eq(%w[bold])
      end

      it "inverts a removal that removed nothing to another no-op" do
        doc = marked_doc
        italic = Prosereflect::Mark::Italic.new
        step = described_class.new(1, italic)
        applied = step.apply(doc).doc
        inverse = step.invert(doc)

        expect(inverse).to be_a(described_class)
        expect(inverse.apply(applied).doc.content[0].raw_marks.map(&:type)).to eq(%w[bold])
      end

      it "stays a no-op when no node sits at the position" do
        doc = marked_doc
        # Position 2 lands inside the text node's characters, on no node token.
        expect(described_class.new(2, bold).invert(doc)).to be_a(described_class)
      end
    end
  end

  # Undo is a round-trip property, so it is tested as one: apply the step, invert it
  # against the document as it stood, apply that, and compare the whole document. One
  # example per node shape -- a single happy path is how the reordering below survived.
  describe "node-mark undo round trip" do
    # doc @0; paragraph token @1; the inline child's token @2.
    def image_doc(marks)
      Prosereflect::Parser.parse_document(
        "type" => "doc",
        "content" => [{ "type" => "paragraph",
                        "content" => [{ "type" => "image", "attrs" => { "src" => "a.png" },
                                        "marks" => marks }] }],
      )
    end

    # doc @0; paragraph token @1; the text node's token @2.
    def text_doc
      Prosereflect::Parser.parse_document(
        "type" => "doc",
        "content" => [{ "type" => "paragraph", "content" => [{ "type" => "text", "text" => "hi" }] }],
      )
    end

    def link(href)
      Prosereflect::Mark::Link.new(attrs: { "href" => href })
    end

    def link_h(href)
      { "type" => "link", "attrs" => { "href" => href } }
    end

    def round_trip(doc, step)
      applied = step.apply(doc)
      expect(applied).to be_ok
      undone = step.invert(doc).apply(applied.doc)
      expect(undone).to be_ok
      undone.doc
    end

    def expect_exact(doc, step)
      expect(round_trip(doc, step).to_h).to eq(doc.to_h)
    end

    def add_mark(pos, mark)
      Prosereflect::Transform::AddNodeMarkStep.new(pos, mark)
    end

    def remove_mark(pos, mark)
      Prosereflect::Transform::RemoveNodeMarkStep.new(pos, mark)
    end

    it "restores a mark added to an unmarked node" do
      expect_exact(image_doc([]), add_mark(2, Prosereflect::Mark::Bold.new))
    end

    it "restores a mark added beside a different-type mark" do
      expect_exact(image_doc([{ "type" => "bold" }]), add_mark(2, Prosereflect::Mark::Italic.new))
    end

    it "restores re-adding a mark the node already carries" do
      expect_exact(image_doc([{ "type" => "bold" }]), add_mark(2, Prosereflect::Mark::Bold.new))
    end

    it "restores a replaced link when it is the only mark" do
      expect_exact(image_doc([link_h("old")]), add_mark(2, link("new")))
    end

    it "restores a replaced link when it is first of two" do
      expect_exact(image_doc([link_h("old"), { "type" => "bold" }]), add_mark(2, link("new")))
    end

    it "restores a replaced link when it is in the middle of three" do
      expect_exact(image_doc([{ "type" => "bold" }, link_h("old"), { "type" => "italic" }]),
                   add_mark(2, link("new")))
    end

    it "restores a removal that removed nothing" do
      expect_exact(image_doc([{ "type" => "bold" }]), remove_mark(2, Prosereflect::Mark::Italic.new))
    end

    it "restores the removal of the node's only mark" do
      expect_exact(image_doc([{ "type" => "bold" }]), remove_mark(2, Prosereflect::Mark::Bold.new))
    end

    it "restores a mark on a text node" do
      expect_exact(text_doc, add_mark(2, Prosereflect::Mark::Bold.new))
    end

    it "restores a mark on a block node" do
      expect_exact(text_doc, add_mark(1, Prosereflect::Mark::Bold.new))
    end

    it "restores a mark on the document node itself" do
      expect_exact(text_doc, add_mark(0, Prosereflect::Mark::Bold.new))
    end

    # The one shape that cannot round-trip exactly, pinned at the property it does have.
    # Undo of a removal re-adds the mark, and a re-added mark has no earlier position to
    # take -- add_to_set can only append when the type is absent. Restoring the index
    # would mean carrying it in the inverse step or ranking mark types; both are design
    # changes rather than fixes, so the gap is recorded here instead of hidden.
    it "restores a removed middle mark as a set but not at its old index" do
      doc = image_doc([{ "type" => "bold" }, link_h("a"), { "type" => "italic" }])
      undone = round_trip(doc, remove_mark(2, link("a")))
      marks = undone.content[0].content[0].raw_marks

      expect(marks.map(&:type)).to contain_exactly("bold", "italic", "link")
      expect(undone.to_h).not_to eq(doc.to_h)
      expect(marks.map(&:type)).to eq(%w[bold italic link])
    end
  end

  # Placing a replacement mark where the old one sat, rather than last, decides whether
  # re-marked runs still match their neighbours -- merge_adjacent_text compares mark
  # arrays element by element.
  describe "range marking and adjacent-run merging" do
    def doc_of(*texts)
      Prosereflect::Parser.parse_document(
        "type" => "doc",
        "content" => [{ "type" => "paragraph", "content" => texts }],
      )
    end

    def txt(str, marks)
      { "type" => "text", "text" => str, "marks" => marks }
    end

    it "leaves a run whole when re-marking part of it changes nothing" do
      doc = doc_of(txt("hello", [{ "type" => "link", "attrs" => { "href" => "a" } }, { "type" => "bold" }]))
      same_link = Prosereflect::Mark::Link.new(attrs: { "href" => "a" })
      result = Prosereflect::Transform::AddMarkStep.new(3, 6, same_link).apply(doc)

      expect(result).to be_ok
      expect(result.doc.to_h).to eq(doc.to_h)
    end

    it "keeps runs separate when they carry the same marks in a different order" do
      doc = doc_of(
        txt("he", [{ "type" => "bold" }, { "type" => "link", "attrs" => { "href" => "a" } }]),
        txt("llo", [{ "type" => "link", "attrs" => { "href" => "b" } }, { "type" => "bold" }]),
      )
      new_link = Prosereflect::Mark::Link.new(attrs: { "href" => "c" })
      result = Prosereflect::Transform::AddMarkStep.new(2, 7, new_link).apply(doc)

      expect(result).to be_ok
      runs = result.doc.content[0].content
      expect(runs.map(&:text)).to eq(%w[he llo])
      expect(runs.map { |r| r.raw_marks.map(&:type) }).to eq([%w[bold link], %w[link bold]])
    end
  end
end
