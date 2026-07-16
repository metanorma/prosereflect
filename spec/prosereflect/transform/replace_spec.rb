# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Replace step operations" do # rubocop:disable RSpec/DescribeClass
  # Helper to build a simple doc with one paragraph containing text
  def build_doc_with_text(text)
    Prosereflect::Parser.parse_document(
      "type" => "doc",
      "content" => [
        { "type" => "paragraph", "content" => [{ "type" => "text", "text" => text }] },
      ],
    )
  end

  # Helper to build a doc with multiple paragraphs
  def build_doc_with_paragraphs(*texts)
    Prosereflect::Parser.parse_document(
      "type" => "doc",
      "content" => texts.map do |t|
        { "type" => "paragraph", "content" => [{ "type" => "text", "text" => t }] }
      end,
    )
  end

  # doc=1 + para=1 + text("Hello")=6 = 8 total
  # Positions: 0=doc start, 1=para start, 2="H", 3="e", 4="l", 5="l", 6="o", 7=para end

  describe "#apply" do
    context "when deleting text" do
      it "deletes a range of text within a paragraph" do
        doc = build_doc_with_text("Hello")
        # Delete "ell" (positions 3-6)
        step = Prosereflect::Transform::ReplaceStep.new(3, 6, Prosereflect::Transform::Slice.empty)
        result = step.apply(doc)

        expect(result).to be_ok
        expect(result.doc).to be_a(Prosereflect::Document)
        expect(result.doc.text_content).to eq("Ho")
      end

      it "keeps the deleted text in a single text node" do
        doc = build_doc_with_text("Hello")
        step = Prosereflect::Transform::ReplaceStep.new(3, 6, Prosereflect::Transform::Slice.empty)
        result = step.apply(doc)

        paragraph = result.doc.content.first
        expect(paragraph).to be_a(Prosereflect::Paragraph)
        expect(paragraph.content.map(&:text)).to eq(["Ho"])
      end

      it "deletes at the start of the document" do
        doc = build_doc_with_text("abc")
        # Delete "ab" (positions 2-4)
        step = Prosereflect::Transform::ReplaceStep.new(2, 4, Prosereflect::Transform::Slice.empty)
        result = step.apply(doc)

        expect(result).to be_ok
        expect(result.doc.text_content).to eq("c")
      end

      it "deletes at the end of the document" do
        doc = build_doc_with_text("abc")
        # Delete "bc" (positions 3-5)
        step = Prosereflect::Transform::ReplaceStep.new(3, 5, Prosereflect::Transform::Slice.empty)
        result = step.apply(doc)

        expect(result).to be_ok
        expect(result.doc.text_content).to eq("a")
      end

      it "deletes an entire paragraph" do
        doc = build_doc_with_text("abc")
        # doc=1, para=1, text("abc")=4, total=6
        # Delete entire paragraph range (1-5)
        step = Prosereflect::Transform::ReplaceStep.new(1, 5, Prosereflect::Transform::Slice.empty)
        result = step.apply(doc)

        expect(result).to be_ok
      end

      it "deletes from start of document to end" do
        doc = build_doc_with_text("abc")
        step = Prosereflect::Transform::ReplaceStep.new(0, doc.node_size, Prosereflect::Transform::Slice.empty)
        result = step.apply(doc)

        expect(result).to be_ok
      end
    end

    context "when replacing text" do
      it "replaces text with new content" do
        doc = build_doc_with_text("Hello")
        replacement = Prosereflect::Transform::Slice.new(
          Prosereflect::Fragment.new([Prosereflect::Text.new(text: "XY")]),
        )
        # Replace "ell" (positions 3-6) with "XY"
        step = Prosereflect::Transform::ReplaceStep.new(3, 6, replacement)
        result = step.apply(doc)

        expect(result).to be_ok
        expect(result.doc.text_content).to eq("HXYo")
      end

      it "replaces a single character" do
        doc = build_doc_with_text("abc")
        replacement = Prosereflect::Transform::Slice.new(
          Prosereflect::Fragment.new([Prosereflect::Text.new(text: "X")]),
        )
        # Replace "b" (position 3-4) with "X"
        step = Prosereflect::Transform::ReplaceStep.new(3, 4, replacement)
        result = step.apply(doc)

        expect(result).to be_ok
      end

      it "replaces text with longer content" do
        doc = build_doc_with_text("ab")
        replacement = Prosereflect::Transform::Slice.new(
          Prosereflect::Fragment.new([Prosereflect::Text.new(text: "XYZ")]),
        )
        # Replace "a" (position 2-3) with "XYZ"
        step = Prosereflect::Transform::ReplaceStep.new(2, 3, replacement)
        result = step.apply(doc)

        expect(result).to be_ok
        expect(result.doc.text_content).to eq("XYZb")
        # New doc should be larger
        expect(result.doc.node_size).to be > doc.node_size
      end

      it "replaces text with shorter content" do
        doc = build_doc_with_text("abcdef")
        replacement = Prosereflect::Transform::Slice.new(
          Prosereflect::Fragment.new([Prosereflect::Text.new(text: "Z")]),
        )
        # Replace "bcde" (positions 3-7) with "Z"
        step = Prosereflect::Transform::ReplaceStep.new(3, 7, replacement)
        result = step.apply(doc)

        expect(result).to be_ok
        expect(result.doc.text_content).to eq("aZf")
        expect(result.doc.node_size).to be < doc.node_size
      end
    end

    context "when inserting text" do
      it "inserts text at a position (zero-width range)" do
        doc = build_doc_with_text("ac")
        insert = Prosereflect::Transform::Slice.new(
          Prosereflect::Fragment.new([Prosereflect::Text.new(text: "b")]),
        )
        # Insert "b" at position 3 (between "a" and "c")
        step = Prosereflect::Transform::ReplaceStep.new(3, 3, insert)
        result = step.apply(doc)

        expect(result).to be_ok
        expect(result.doc.text_content).to eq("abc")
        expect(result.doc.node_size).to be > doc.node_size
      end

      it "inserts at the beginning of a paragraph" do
        doc = build_doc_with_text("cd")
        insert = Prosereflect::Transform::Slice.new(
          Prosereflect::Fragment.new([Prosereflect::Text.new(text: "ab")]),
        )
        # Insert at position 2 (start of text inside paragraph)
        step = Prosereflect::Transform::ReplaceStep.new(2, 2, insert)
        result = step.apply(doc)

        expect(result).to be_ok
        expect(result.doc.text_content).to eq("abcd")
      end

      it "inserts at the end of a paragraph" do
        doc = build_doc_with_text("ab")
        # doc=1, para=1, text("ab")=3, total=5
        insert = Prosereflect::Transform::Slice.new(
          Prosereflect::Fragment.new([Prosereflect::Text.new(text: "cd")]),
        )
        # Insert at position 4 (end of text)
        step = Prosereflect::Transform::ReplaceStep.new(4, 4, insert)
        result = step.apply(doc)

        expect(result).to be_ok
        expect(result.doc.text_content).to eq("abcd")
      end
    end

    context "with Slice objects" do
      it "replaces content with a slice containing multiple text nodes" do
        doc = build_doc_with_text("Hello")
        replacement = Prosereflect::Transform::Slice.new(
          Prosereflect::Fragment.new(
            [
              Prosereflect::Text.new(text: "X"),
              Prosereflect::Text.new(text: "Y"),
            ],
          ),
        )
        step = Prosereflect::Transform::ReplaceStep.new(2, 7, replacement)
        result = step.apply(doc)

        expect(result).to be_ok
        expect(result.doc.text_content).to eq("XY")
      end

      it "merges adjacent replacement text nodes into one node" do
        doc = build_doc_with_text("Hello")
        replacement = Prosereflect::Transform::Slice.new(
          Prosereflect::Fragment.new(
            [Prosereflect::Text.new(text: "X"), Prosereflect::Text.new(text: "Y")],
          ),
        )
        step = Prosereflect::Transform::ReplaceStep.new(2, 7, replacement)
        result = step.apply(doc)

        # Each text node adds +1 to node_size, so leaving these unmerged would
        # corrupt every downstream position.
        expect(result.doc.content.first.content.map(&:text)).to eq(["XY"])
      end

      it "replaces with an empty slice that has open boundaries" do
        doc = build_doc_with_text("abc")
        slice = Prosereflect::Transform::Slice.new(
          Prosereflect::Fragment.new([]),
          1,
          0,
        )
        step = Prosereflect::Transform::ReplaceStep.new(2, 5, slice)
        result = step.apply(doc)

        # Open depths describe how slice *content* joins; with no content they
        # are inert, so this is a plain deletion.
        expect(result).to be_ok
        expect(result.doc.text_content).to eq("")
      end

      it "rejects a slice whose open boundaries would affect the result" do
        doc = build_doc_with_text("abc")
        slice = Prosereflect::Transform::Slice.new(
          Prosereflect::Fragment.new([Prosereflect::Text.new(text: "z")]),
          1,
          0,
        )
        step = Prosereflect::Transform::ReplaceStep.new(2, 5, slice)
        result = step.apply(doc)

        expect(result).not_to be_ok
        expect(result.failed).to match(/open/i)
      end

      it "replaces a paragraph with a slice containing a paragraph" do
        doc = build_doc_with_text("old")
        new_para = Prosereflect::Paragraph.new(type: "paragraph")
        new_para.add_text("new")
        replacement = Prosereflect::Transform::Slice.new(
          Prosereflect::Fragment.new([new_para]),
        )
        # Replace entire paragraph content (positions 1-5)
        step = Prosereflect::Transform::ReplaceStep.new(1, 5, replacement)
        result = step.apply(doc)

        expect(result).to be_ok
      end
    end

    context "with leaf nodes" do
      # A leaf occupies a position but has no interior, so a caret just past its
      # token belongs after it. Descending into one produces e.g. a hard_break
      # containing text, and the inserted text disappears from text_content.
      it "inserts after a hard_break rather than inside it" do
        doc = Prosereflect::Parser.parse_document(
          "type" => "doc",
          "content" => [
            { "type" => "paragraph",
              "content" => [{ "type" => "hard_break" }, { "type" => "text", "text" => "a" }] },
          ],
        )
        insert = Prosereflect::Transform::Slice.new(
          Prosereflect::Fragment.new([Prosereflect::Text.new(text: "X")]),
        )
        result = Prosereflect::Transform::ReplaceStep.new(3, 3, insert).apply(doc)

        expect(result).to be_ok
        # Text#content is nil too, so asserting only text_content and a nil first
        # child would pass for [text("X"), text("a")] -- assert the break itself
        # and the text order. "a" lies wholly after the insertion point, so it is
        # untouched and "X" abuts it rather than coalescing.
        children = result.doc.content.first.content
        expect(children.map(&:type)).to eq(%w[hard_break text text])
        expect(children.drop(1).map(&:text)).to eq(%w[X a])
        expect(children.first.content).to be_nil
      end

      it "inserts after a user mention rather than inside it" do
        doc = Prosereflect::Parser.parse_document(
          "type" => "doc",
          "content" => [
            { "type" => "paragraph",
              "content" => [{ "type" => "user", "attrs" => { "id" => "u1" } },
                            { "type" => "text", "text" => "a" }] },
          ],
        )
        insert = Prosereflect::Transform::Slice.new(
          Prosereflect::Fragment.new([Prosereflect::Text.new(text: "X")]),
        )
        result = Prosereflect::Transform::ReplaceStep.new(3, 3, insert).apply(doc)

        expect(result).to be_ok
        # User#text_content is empty and both inserts are type "text", so neither
        # text_content nor the type list can tell where "X" landed. Assert the
        # actual text order, and that the mention took no children.
        children = result.doc.content.first.content
        expect(children.map(&:type)).to eq(%w[user text text])
        expect(children.drop(1).map(&:text)).to eq(%w[X a])
        expect(children.first.content).to eq([])
      end
    end

    context "when inserting an empty text node" do
      # An empty text node is not representable content -- ProseMirror's
      # schema.text("") throws -- and with no characters there is nothing for its
      # marks to apply to. Dropping it is canonical normalisation, so the step
      # succeeds and the document is untouched.
      it "is a no-op that leaves the document unchanged" do
        doc = build_doc_with_text("ab")
        slice = Prosereflect::Transform::Slice.new(
          Prosereflect::Fragment.new(
            [Prosereflect::Text.new(text: "", marks: [{ "type" => "bold" }])],
          ),
        )
        result = Prosereflect::Transform::ReplaceStep.new(3, 3, slice).apply(doc)

        expect(result).to be_ok
        expect(result.doc.to_h).to eq(doc.to_h)
      end
    end

    # KNOWN LIMITATION, asserted so it cannot pass unnoticed: replace is not
    # schema-aware. A plain Node carries no NodeType, so replace cannot know what
    # a parent may contain and places content wherever the position resolves. The
    # inward/outward tie-break is right for Document, where blocks are valid
    # siblings, and cannot know it is wrong inside a list. Fixing this means
    # consulting lib/prosereflect/schema; see docs/plans/fix-replace-step.md.
    # Asserts today's behaviour, NOT the desired behaviour.
    context "when inserting a block into a list" do
      it "places the block as an invalid sibling of the list items" do
        doc = Prosereflect::Document.create
        list = doc.add_bullet_list
        list.add_item("a")
        list.add_item("b")

        para = Prosereflect::Paragraph.create
        para.add_text("X")
        slice = Prosereflect::Transform::Slice.new(Prosereflect::Fragment.new([para]))
        result = Prosereflect::Transform::ReplaceStep.new(6, 6, slice).apply(doc)

        expect(result).to be_ok
        # bullet_list accepts only list_item; a paragraph here is schema-invalid.
        expect(result.doc.content.first.content.map(&:type))
          .to eq(%w[list_item paragraph list_item])
      end
    end

    context "when children lie outside the replaced range" do
      it "leaves untouched sibling text nodes alone" do
        doc = Prosereflect::Parser.parse_document(
          "type" => "doc",
          "content" => [
            { "type" => "paragraph",
              "content" => [{ "type" => "text", "text" => "a" },
                            { "type" => "text", "text" => "b" },
                            { "type" => "text", "text" => "Z" }] },
          ],
        )
        replacement = Prosereflect::Transform::Slice.new(
          Prosereflect::Fragment.new([Prosereflect::Text.new(text: "Q")]),
        )
        # Replace "b" only. Coalescing "a"/"Z" into it would shift node_size by
        # -2 for an edit whose delta is 0, moving every position after it.
        result = Prosereflect::Transform::ReplaceStep.new(4, 5, replacement).apply(doc)

        expect(result.doc.content.first.content.map(&:text)).to eq(%w[a Q Z])
        expect(result.doc.node_size).to eq(doc.node_size)
      end
    end

    context "when inserting at a child boundary" do
      # This model gives a node no closing token, so a position at a child's end
      # is ambiguous: both the end of that child's content and the start of its
      # next sibling. Inline content resolves inward (it has nowhere valid to
      # live among block siblings); block content resolves outward.
      def inline_slice(text)
        Prosereflect::Transform::Slice.new(
          Prosereflect::Fragment.new([Prosereflect::Text.new(text: text)]),
        )
      end

      it "inserts text into an empty paragraph rather than beside it" do
        doc = Prosereflect::Parser.parse_document(
          "type" => "doc", "content" => [{ "type" => "paragraph" }],
        )
        result = Prosereflect::Transform::ReplaceStep.new(2, 2, inline_slice("X")).apply(doc)

        expect(result).to be_ok
        expect(result.doc.content.length).to eq(1)
        expect(result.doc.content.first.content.map(&:text)).to eq(["X"])
      end

      it "inserts text after a trailing hard_break rather than beside the paragraph" do
        doc = Prosereflect::Parser.parse_document(
          "type" => "doc",
          "content" => [{ "type" => "paragraph", "content" => [{ "type" => "hard_break" }] }],
        )
        result = Prosereflect::Transform::ReplaceStep.new(3, 3, inline_slice("X")).apply(doc)

        expect(result).to be_ok
        expect(result.doc.content.length).to eq(1)
        expect(result.doc.content.first.content.map(&:type)).to eq(%w[hard_break text])
      end

      # Inline atoms are leaves but still inline, so they resolve inward like
      # text. HorizontalRule is a leaf too, but a block one, so it stays outward.
      it "inserts an inline atom into the paragraph rather than beside it" do
        doc = build_doc_with_text("abc")
        # para spans [1,6), so 6 is the boundary
        insert = Prosereflect::Transform::Slice.new(
          Prosereflect::Fragment.new([Prosereflect::HardBreak.new]),
        )
        result = Prosereflect::Transform::ReplaceStep.new(6, 6, insert).apply(doc)

        expect(result).to be_ok
        expect(result.doc.content.map(&:type)).to eq(["paragraph"])
        expect(result.doc.content.first.content.map(&:type)).to eq(%w[text hard_break])
      end

      it "keeps a horizontal_rule beside the paragraph as a block leaf" do
        doc = build_doc_with_text("abc")
        insert = Prosereflect::Transform::Slice.new(
          Prosereflect::Fragment.new([Prosereflect::HorizontalRule.new]),
        )
        result = Prosereflect::Transform::ReplaceStep.new(6, 6, insert).apply(doc)

        expect(result.doc.content.map(&:type)).to eq(%w[paragraph horizontal_rule])
      end

      it "appends text to the preceding paragraph at a block boundary" do
        doc = build_doc_with_paragraphs("abc", "def")
        result = Prosereflect::Transform::ReplaceStep.new(6, 6, inline_slice("X")).apply(doc)

        expect(result.doc.text_content).to eq("abcX\ndef")
        # "abc" is wholly outside the range, so it is carried across untouched
        # and the insert abuts it rather than coalescing into it.
        expect(result.doc.content.map { |node| node.content.map(&:text) })
          .to eq([%w[abc X], ["def"]])
      end

      it "inserts a paragraph between two paragraphs rather than nesting it" do
        doc = build_doc_with_paragraphs("abc", "def")
        # para1 spans [1,6), para2 spans [6,11)
        para = Prosereflect::Paragraph.new(type: "paragraph")
        para.add_text("X")
        insert = Prosereflect::Transform::Slice.new(Prosereflect::Fragment.new([para]))
        result = Prosereflect::Transform::ReplaceStep.new(6, 6, insert).apply(doc)

        expect(result).to be_ok
        expect(result.doc.content.map { |node| node.content.map(&:text) })
          .to eq([["abc"], ["X"], ["def"]])
      end
    end

    context "when text carries marks" do
      it "merges replacement text into unmarked text regardless of nil/empty marks" do
        doc = Prosereflect::Parser.parse_document(
          "type" => "doc",
          "content" => [
            { "type" => "paragraph",
              "content" => [{ "type" => "text", "text" => "ab", "marks" => [] }] },
          ],
        )
        insert = Prosereflect::Transform::Slice.new(
          Prosereflect::Fragment.new([Prosereflect::Text.new(text: "X")]),
        )
        result = Prosereflect::Transform::ReplaceStep.new(2, 3, insert).apply(doc)

        expect(result.doc.content.first.content.map(&:text)).to eq(["Xb"])
      end

      it "does not merge text carrying different marks" do
        doc = Prosereflect::Parser.parse_document(
          "type" => "doc",
          "content" => [
            { "type" => "paragraph",
              "content" => [{ "type" => "text", "text" => "ab" }] },
          ],
        )
        bold = Prosereflect::Text.new(text: "X", marks: [{ "type" => "bold" }])
        insert = Prosereflect::Transform::Slice.new(Prosereflect::Fragment.new([bold]))
        result = Prosereflect::Transform::ReplaceStep.new(2, 3, insert).apply(doc)

        expect(result.doc.content.first.content.map(&:text)).to eq(%w[X b])
      end
    end

    context "with validation" do
      it "fails when from > to" do
        doc = build_doc_with_text("abc")
        step = Prosereflect::Transform::ReplaceStep.new(5, 2, Prosereflect::Transform::Slice.empty)
        result = step.apply(doc)

        expect(result).not_to be_ok
        expect(result.failed).to eq("Invalid positions")
      end

      it "fails when from is negative" do
        doc = build_doc_with_text("abc")
        step = Prosereflect::Transform::ReplaceStep.new(-1, 2, Prosereflect::Transform::Slice.empty)
        result = step.apply(doc)

        expect(result).not_to be_ok
        expect(result.failed).to eq("from < 0")
      end

      it "fails when to exceeds document size" do
        doc = build_doc_with_text("abc")
        # doc.node_size = 6
        step = Prosereflect::Transform::ReplaceStep.new(2, 100, Prosereflect::Transform::Slice.empty)
        result = step.apply(doc)

        expect(result).not_to be_ok
        expect(result.failed).to eq("to > doc size")
      end

      it "succeeds when from equals to (insertion)" do
        doc = build_doc_with_text("abc")
        slice = Prosereflect::Transform::Slice.new(
          Prosereflect::Fragment.new([Prosereflect::Text.new(text: "x")]),
        )
        step = Prosereflect::Transform::ReplaceStep.new(3, 3, slice)
        result = step.apply(doc)

        expect(result).to be_ok
      end

      it "succeeds when from=0 and to=doc.node_size (replace entire document)" do
        doc = build_doc_with_text("abc")
        step = Prosereflect::Transform::ReplaceStep.new(0, doc.node_size, Prosereflect::Transform::Slice.empty)
        result = step.apply(doc)

        expect(result).to be_ok
      end
    end
  end

  describe "#invert" do
    it "produces a ReplaceStep that reverses a deletion" do
      doc = build_doc_with_text("Hello")
      # Delete "ell" (positions 3-6)
      step = Prosereflect::Transform::ReplaceStep.new(3, 6, Prosereflect::Transform::Slice.empty)
      inverted = step.invert(doc)

      expect(inverted).to be_a(Prosereflect::Transform::ReplaceStep)
      # invert: ReplaceStep.new(@from, @from + @slice.size, removed)
      # @from=3, @slice.size=0 (empty slice), so inverted.to = 3 + 0 = 3
      expect(inverted.from).to eq(3)
      expect(inverted.to).to eq(3)
      # removed should contain the content that was between 3 and 6
      expect(inverted.slice).not_to be_nil
    end

    it "produces a step that reverses an insertion" do
      doc = build_doc_with_text("ac")
      insert = Prosereflect::Transform::Slice.new(
        Prosereflect::Fragment.new([Prosereflect::Text.new(text: "b")]),
      )
      step = Prosereflect::Transform::ReplaceStep.new(3, 3, insert)
      inverted = step.invert(doc)

      expect(inverted).to be_a(Prosereflect::Transform::ReplaceStep)
      # invert: from = 3, to = 3 + slice.size
      # slice contains text "b" (node_size=2), slice.size = 2 + 0 + 0 = 2
      expect(inverted.from).to eq(3)
      expect(inverted.to).to eq(5)
      # The inverted step's slice is the content that was at positions 3-3 (empty)
      expect(inverted.slice).to be_a(Prosereflect::Transform::Slice)
      expect(inverted.slice.empty?).to be true
    end

    it "produces an inverse whose slice apply can read" do
      doc = build_doc_with_text("Hello")
      step = Prosereflect::Transform::ReplaceStep.new(3, 6, Prosereflect::Transform::Slice.empty)
      deleted = step.apply(doc)
      expect(deleted.doc.text_content).to eq("Ho")

      # An inverse whose slice is a bare Fragment fails in apply, which reads
      # open_start/open_end off the slice.
      expect(step.invert(doc).apply(deleted.doc)).to be_ok
    end

    # KNOWN LIMITATION, asserted so it cannot pass unnoticed: an inverse does NOT
    # round-trip. content_between collects whole visited nodes via nodes_between
    # (which yields at every depth) rather than cutting the removed range, so the
    # inverse of deleting "ell" carries the entire Paragraph("Hello") and
    # re-applying it nests a paragraph inside a paragraph. Capturing the removed
    # range properly needs the same slice/open-depth machinery that is out of
    # scope here (see docs/plans/fix-replace-step.md). Asserting today's
    # behaviour, NOT the desired behaviour.
    it "does not round-trip: the inverse re-inserts whole visited nodes" do
      doc = build_doc_with_text("Hello")
      step = Prosereflect::Transform::ReplaceStep.new(3, 6, Prosereflect::Transform::Slice.empty)
      deleted = step.apply(doc)
      restored = step.invert(doc).apply(deleted.doc)

      expect(restored.doc.text_content).to eq("HHelloo")
      expect(restored.doc.text_content).not_to eq(doc.text_content)
    end

    it "produces a step that reverses a replacement" do
      doc = build_doc_with_text("Hello")
      replacement = Prosereflect::Transform::Slice.new(
        Prosereflect::Fragment.new([Prosereflect::Text.new(text: "XY")]),
      )
      step = Prosereflect::Transform::ReplaceStep.new(3, 6, replacement)
      inverted = step.invert(doc)

      expect(inverted).to be_a(Prosereflect::Transform::ReplaceStep)
      # invert: from = 3, to = 3 + slice.size = 3 + 3 (text "XY" = node_size 3)
      expect(inverted.from).to eq(3)
      expect(inverted.to).to eq(6)
      # The inverted slice should contain what was at positions 3-6
      expect(inverted.slice).not_to be_nil
    end

    it "inverted step has correct from position matching original step from" do
      doc = build_doc_with_text("Hello")
      step = Prosereflect::Transform::ReplaceStep.new(2, 7, Prosereflect::Transform::Slice.empty)
      inverted = step.invert(doc)

      expect(inverted.from).to eq(2)
    end

    it "inverted step to equals from plus slice size" do
      doc = build_doc_with_text("Hello")
      replacement = Prosereflect::Transform::Slice.new(
        Prosereflect::Fragment.new([Prosereflect::Text.new(text: "abc")]),
      )
      step = Prosereflect::Transform::ReplaceStep.new(2, 7, replacement)
      inverted = step.invert(doc)

      # slice.size for text "abc" = node_size 4 + open_start 0 + open_end 0 = 4
      expect(inverted.to).to eq(2 + replacement.size)
    end
  end

  describe "#get_map" do
    it "returns a StepMap with correct ranges for deletion" do
      # Delete positions 3-6
      step = Prosereflect::Transform::ReplaceStep.new(3, 6, Prosereflect::Transform::Slice.empty)
      step_map = step.get_map

      expect(step_map).to be_a(Prosereflect::Transform::StepMap)
      # delta = 0 - (6-3) = -3
      # ranges: [[3, 6, 3, 0]]
      expect(step_map.ranges).to eq([[3, 6, 3, 0]])
    end

    it "returns a StepMap with correct ranges for insertion" do
      # Insert "XY" (node_size=3) at position 2
      slice = Prosereflect::Transform::Slice.new(
        Prosereflect::Fragment.new([Prosereflect::Text.new(text: "XY")]),
      )
      step = Prosereflect::Transform::ReplaceStep.new(2, 2, slice)
      step_map = step.get_map

      # delta = 3 - (2-2) = 3
      # ranges: [[2, 2, 2, 5]]
      expect(step_map.ranges).to eq([[2, 2, 2, 5]])
    end

    it "returns a StepMap with correct ranges for same-size replacement" do
      # Replace 3 positions with 3-node_size content (net zero)
      slice = Prosereflect::Transform::Slice.new(
        Prosereflect::Fragment.new([Prosereflect::Text.new(text: "ab")]),
      )
      step = Prosereflect::Transform::ReplaceStep.new(2, 5, slice)
      step_map = step.get_map

      # delta = 3 - (5-2) = 0
      # ranges: [[2, 5, 2, 2]]
      expect(step_map.ranges).to eq([[2, 5, 2, 2]])
    end

    it "maps positions before deletion range unchanged" do
      step = Prosereflect::Transform::ReplaceStep.new(3, 6, Prosereflect::Transform::Slice.empty)
      step_map = step.get_map

      # Position 1 is before range start 3, so it stays unchanged
      expect(step_map.map(1)).to eq(1)
      expect(step_map.map(2)).to eq(2)
    end

    it "maps positions after deletion range with offset" do
      step = Prosereflect::Transform::ReplaceStep.new(3, 6, Prosereflect::Transform::Slice.empty)
      step_map = step.get_map

      # For range [3,6,3,0]: positions >= 6 get offset by (new_end - old_end) = (0-6) = -6
      # pos 6 -> 0, pos 7 -> 1, pos 8 -> 2
      expect(step_map.map(6)).to eq(0)
      expect(step_map.map(7)).to eq(1)
      expect(step_map.map(8)).to eq(2)
    end

    it "maps positions after insertion range with positive offset" do
      slice = Prosereflect::Transform::Slice.new(
        Prosereflect::Fragment.new([Prosereflect::Text.new(text: "XY")]),
      )
      step = Prosereflect::Transform::ReplaceStep.new(2, 2, slice)
      step_map = step.get_map

      # For range [2,2,2,5]: positions >= 2 get offset by (5-2) = 3
      expect(step_map.map(5)).to eq(8)
    end

    it "marks positions in deleted range as deleted" do
      step = Prosereflect::Transform::ReplaceStep.new(3, 6, Prosereflect::Transform::Slice.empty)
      step_map = step.get_map

      expect(step_map.deleted?(4)).to be true
      expect(step_map.deleted?(2)).to be false
      expect(step_map.deleted?(7)).to be false
    end

    it "returns correct map_result for deleted positions" do
      step = Prosereflect::Transform::ReplaceStep.new(3, 6, Prosereflect::Transform::Slice.empty)
      step_map = step.get_map

      result = step_map.map_result(4)
      expect(result.deleted).to be true
    end

    it "returns correct map_result for non-deleted positions" do
      step = Prosereflect::Transform::ReplaceStep.new(3, 6, Prosereflect::Transform::Slice.empty)
      step_map = step.get_map

      result = step_map.map_result(2)
      expect(result.deleted).to be false
      expect(result.pos).to eq(2)
    end
  end

  describe "mapping through Mapping" do
    it "maps positions through a single deletion step" do
      step = Prosereflect::Transform::ReplaceStep.new(3, 6, Prosereflect::Transform::Slice.empty)
      mapping = Prosereflect::Transform::Mapping.from_step_map(step.get_map)

      # Position 1 is before deletion range, stays the same
      expect(mapping.map(1)).to eq(1)
      # Position 7 is after deletion range, gets offset by -6
      expect(mapping.map(7)).to eq(1)
    end

    it "maps positions through a single insertion step" do
      slice = Prosereflect::Transform::Slice.new(
        Prosereflect::Fragment.new([Prosereflect::Text.new(text: "XY")]),
      )
      step = Prosereflect::Transform::ReplaceStep.new(2, 2, slice)
      mapping = Prosereflect::Transform::Mapping.from_step_map(step.get_map)

      # Position 1 is before insertion, stays the same
      expect(mapping.map(1)).to eq(1)
      # Position 5 is after insertion, shifts by +3
      expect(mapping.map(5)).to eq(8)
    end

    it "maps positions through multiple steps" do
      # First step: delete positions 3-6
      step1 = Prosereflect::Transform::ReplaceStep.new(3, 6, Prosereflect::Transform::Slice.empty)
      # Second step: delete positions 4-6 (in the post-step1 doc)
      step2 = Prosereflect::Transform::ReplaceStep.new(4, 6, Prosereflect::Transform::Slice.empty)

      mapping = Prosereflect::Transform::Mapping.new
      mapping.add_map(step1.get_map)
      mapping.add_map(step2.get_map)

      # Position 8 should be mapped through both steps
      mapped = mapping.map(8)
      expect(mapped).to be < 8
    end

    it "maps positions through empty mapping as identity" do
      mapping = Prosereflect::Transform::Mapping.new
      expect(mapping.map(5)).to eq(5)
    end

    it "reports deleted positions via map_result" do
      step = Prosereflect::Transform::ReplaceStep.new(3, 6, Prosereflect::Transform::Slice.empty)
      mapping = Prosereflect::Transform::Mapping.from_step_map(step.get_map)

      result = mapping.map_result(4)
      expect(result[:deleted]).to be true
    end

    it "reports non-deleted positions via map_result" do
      step = Prosereflect::Transform::ReplaceStep.new(3, 6, Prosereflect::Transform::Slice.empty)
      mapping = Prosereflect::Transform::Mapping.from_step_map(step.get_map)

      result = mapping.map_result(2)
      expect(result[:deleted]).to be false
      expect(result[:pos]).to eq(2)
    end

    it "adds step maps at specific indices" do
      mapping = Prosereflect::Transform::Mapping.new
      step1 = Prosereflect::Transform::ReplaceStep.new(3, 6, Prosereflect::Transform::Slice.empty)
      step2 = Prosereflect::Transform::ReplaceStep.new(4, 8, Prosereflect::Transform::Slice.empty)

      mapping.add_map(step1.get_map)
      mapping.add_map(step2.get_map, 0)

      expect(mapping.to_a.length).to eq(2)
    end
  end

  describe "ReplaceAroundStep" do
    describe "creation" do
      it "creates a ReplaceAroundStep with all parameters" do
        slice = Prosereflect::Transform::Slice.new(
          Prosereflect::Fragment.new([Prosereflect::Blockquote.create]),
        )
        step = Prosereflect::Transform::ReplaceAroundStep.new(
          1, 7, 1, 7, slice, 0, structure: false
        )

        expect(step.from).to eq(1)
        expect(step.to).to eq(7)
        expect(step.gap_from).to eq(1)
        expect(step.gap_to).to eq(7)
        expect(step.insert).to eq(0)
        expect(step.structure).to be false
      end

      it "defaults structure to false" do
        slice = Prosereflect::Transform::Slice.empty
        step = Prosereflect::Transform::ReplaceAroundStep.new(
          1, 5, 1, 5, slice, 0
        )
        expect(step.structure).to be false
      end

      it "sets structure to true when specified" do
        slice = Prosereflect::Transform::Slice.empty
        step = Prosereflect::Transform::ReplaceAroundStep.new(
          1, 5, 1, 5, slice, 0, structure: true
        )
        expect(step.structure).to be true
      end
    end

    describe "#step_type" do
      it "returns replaceAround" do
        step = Prosereflect::Transform::ReplaceAroundStep.new(
          1, 5, 1, 5, Prosereflect::Transform::Slice.empty, 0
        )
        expect(step.step_type).to eq("replaceAround")
      end
    end

    describe "#get_map" do
      it "returns a StepMap for the around-replacement" do
        slice = Prosereflect::Transform::Slice.new(
          Prosereflect::Fragment.new([Prosereflect::Blockquote.create]),
        )
        step = Prosereflect::Transform::ReplaceAroundStep.new(
          1, 7, 1, 7, slice, 0
        )
        step_map = step.get_map

        expect(step_map).to be_a(Prosereflect::Transform::StepMap)
        expect(step_map.ranges).to be_an(Array)
        expect(step_map.ranges.length).to be > 0
      end

      it "produces correct ranges for a wrapping operation" do
        # Wrapping a paragraph: from=1, to=7, gap_from=1, gap_to=7
        # Slice is a blockquote (node_size=1), insert=0
        slice = Prosereflect::Transform::Slice.new(
          Prosereflect::Fragment.new([Prosereflect::Blockquote.create]),
        )
        step = Prosereflect::Transform::ReplaceAroundStep.new(
          1, 7, 1, 7, slice, 0
        )
        step_map = step.get_map

        # get_map returns: [from, gap_from-from, insert, gap_to, to-gap_to, slice.size-insert]
        # = [1, 0, 0, 7, 0, 1]
        expect(step_map.ranges).to eq([1, 0, 0, 7, 0, 1])
      end

      it "produces correct ranges for a lift operation" do
        # Lift: from=1, to=9, gap_from=3, gap_to=7, slice=empty, insert=0
        slice = Prosereflect::Transform::Slice.empty
        step = Prosereflect::Transform::ReplaceAroundStep.new(
          1, 9, 3, 7, slice, 0
        )
        step_map = step.get_map

        # get_map returns: [1, 2, 0, 7, 2, 0]
        expect(step_map.ranges).to eq([1, 2, 0, 7, 2, 0])
      end
    end

    describe "#to_json" do
      it "serializes core fields to a hash" do
        slice = Prosereflect::Transform::Slice.new(
          Prosereflect::Fragment.new([Prosereflect::Blockquote.create]),
        )
        step = Prosereflect::Transform::ReplaceAroundStep.new(
          1, 7, 1, 7, slice, 0, structure: true
        )

        # Verify attributes directly since to_json has a bug with Fragment#map
        expect(step.step_type).to eq("replaceAround")
        expect(step.from).to eq(1)
        expect(step.to).to eq(7)
        expect(step.gap_from).to eq(1)
        expect(step.gap_to).to eq(7)
        expect(step.insert).to eq(0)
        expect(step.structure).to be true
      end

      it "calls to_json which builds the expected hash structure" do
        slice = Prosereflect::Transform::Slice.new(
          Prosereflect::Fragment.new([Prosereflect::Blockquote.create]),
        )
        step = Prosereflect::Transform::ReplaceAroundStep.new(
          1, 7, 1, 7, slice, 0, structure: true
        )
        json = step.to_json

        expect(json["stepType"]).to eq("replaceAround")
        expect(json["from"]).to eq(1)
        expect(json["to"]).to eq(7)
        expect(json["gapFrom"]).to eq(1)
        expect(json["gapTo"]).to eq(7)
        expect(json["insert"]).to eq(0)
        expect(json["structure"]).to be true
        expect(json["slice"]).to be_an(Array)
      end
    end
  end

  describe "edge cases" do
    context "with empty document content" do
      it "applies a step to an empty paragraph" do
        doc = Prosereflect::Parser.parse_document(
          "type" => "doc",
          "content" => [
            { "type" => "paragraph" },
          ],
        )
        # Empty paragraph: doc=1, para=1, total=2
        insert = Prosereflect::Transform::Slice.new(
          Prosereflect::Fragment.new([Prosereflect::Text.new(text: "hi")]),
        )
        step = Prosereflect::Transform::ReplaceStep.new(2, 2, insert)
        result = step.apply(doc)

        expect(result).to be_ok
      end

      it "inserts into an empty document" do
        doc = Prosereflect::Parser.parse_document(
          "type" => "doc",
          "content" => [],
        )
        # Empty doc: node_size=1
        expect(doc.node_size).to eq(1)
        # Cannot insert at position 2 since doc size is 1
        step = Prosereflect::Transform::ReplaceStep.new(1, 1, Prosereflect::Transform::Slice.empty)
        result = step.apply(doc)

        expect(result).to be_ok
      end
    end

    context "with nested structures" do
      it "replaces content inside a nested blockquote" do
        doc = Prosereflect::Parser.parse_document(
          "type" => "doc",
          "content" => [
            {
              "type" => "blockquote",
              "content" => [
                { "type" => "paragraph", "content" => [{ "type" => "text", "text" => "quoted" }] },
              ],
            },
          ],
        )
        # doc=1 + bq=1 + para=1 + text("quoted")=7 = 10
        # Delete text inside blockquote (positions 4-9)
        step = Prosereflect::Transform::ReplaceStep.new(4, 9, Prosereflect::Transform::Slice.empty)
        result = step.apply(doc)

        expect(result).to be_ok
      end

      it "applies a step to a document with multiple block types" do
        doc = Prosereflect::Parser.parse_document(
          "type" => "doc",
          "content" => [
            { "type" => "paragraph", "content" => [{ "type" => "text", "text" => "first" }] },
            { "type" => "heading", "attrs" => { "level" => 2 },
              "content" => [{ "type" => "text", "text" => "title" }] },
            { "type" => "paragraph", "content" => [{ "type" => "text", "text" => "last" }] },
          ],
        )
        # Delete the heading (positions 8-15)
        # first para: 1+1+6=8, heading: 1+1+6=8, heading starts at pos 8
        step = Prosereflect::Transform::ReplaceStep.new(8, 15, Prosereflect::Transform::Slice.empty)
        result = step.apply(doc)

        expect(result).to be_ok
      end
    end

    # A cross-block range trims each block but does NOT merge the surviving
    # blocks into one. Joining is what a slice's open_start/open_end depths
    # drive, and those are not implemented (see docs/plans/fix-replace-step.md).
    # ProseMirror would collapse these into a single paragraph.
    context "when replacing across node boundaries" do
      it "deletes content spanning two paragraphs" do
        doc = build_doc_with_paragraphs("ab", "cd")
        # doc=1 + (para=1+text=3) + (para=1+text=3) = 9
        # Positions: 0=doc, 1=para1, 2="a", 3="b", 4=para1_end/para2_start
        #            5=para2, 6="c", 7="d", 8=end
        # Delete from middle of para1 to middle of para2 (3-7)
        step = Prosereflect::Transform::ReplaceStep.new(3, 7, Prosereflect::Transform::Slice.empty)
        result = step.apply(doc)

        expect(result).to be_ok
        expect(result.doc.content.map { |para| para.content.map(&:text) }).to eq([["a"], ["d"]])
      end

      it "leaves the two paragraphs unjoined rather than merging them" do
        doc = build_doc_with_paragraphs("ab", "cd")
        step = Prosereflect::Transform::ReplaceStep.new(3, 7, Prosereflect::Transform::Slice.empty)
        result = step.apply(doc)

        # Documents current behaviour, not desired ProseMirror parity: a join
        # would yield a single paragraph "ad".
        expect(result.doc.content.length).to eq(2)
      end

      it "replaces content spanning two paragraphs with new content" do
        doc = build_doc_with_paragraphs("ab", "cd")
        replacement = Prosereflect::Transform::Slice.new(
          Prosereflect::Fragment.new([Prosereflect::Text.new(text: "XY")]),
        )
        step = Prosereflect::Transform::ReplaceStep.new(3, 7, replacement)
        result = step.apply(doc)

        expect(result).to be_ok
      end

      # KNOWN LIMITATION, asserted so it cannot pass unnoticed: an inline slice
      # replacing a cross-block range is spliced at the doc level, producing a
      # text node as a sibling of paragraphs -- which is not a valid ProseMirror
      # document (text may only live inside a block). Placing it correctly needs
      # the open-depth fitting that is out of scope here; see the plan. This
      # asserts today's behaviour, NOT the desired behaviour.
      it "splices an inline slice at doc level across a block boundary (invalid doc)" do
        doc = build_doc_with_paragraphs("ab", "cd")
        replacement = Prosereflect::Transform::Slice.new(
          Prosereflect::Fragment.new([Prosereflect::Text.new(text: "XY")]),
        )
        step = Prosereflect::Transform::ReplaceStep.new(3, 7, replacement)
        result = step.apply(doc)

        expect(result.doc.to_h).to eq(
          { "type" => "doc",
            "content" => [
              { "type" => "paragraph", "content" => [{ "type" => "text", "text" => "a" }] },
              { "type" => "text", "text" => "XY" },
              { "type" => "paragraph", "content" => [{ "type" => "text", "text" => "d" }] },
            ] },
        )
      end
    end

    context "with table structures" do
      it "deletes content inside a table cell" do
        doc = Prosereflect::Parser.parse_document(
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
                        { "type" => "paragraph",
                          "content" => [{ "type" => "text", "text" => "cell" }] },
                      ],
                    },
                  ],
                },
              ],
            },
          ],
        )
        # doc=1, table=1, row=1, cell=1, para=1, text("cell")=5 = 10
        # Positions inside text: 6="c", 7="e", 8="l", 9="l"
        step = Prosereflect::Transform::ReplaceStep.new(7, 9, Prosereflect::Transform::Slice.empty)
        result = step.apply(doc)

        expect(result).to be_ok
      end
    end

    context "with Slice operations" do
      it "Slice.empty creates a truly empty slice" do
        slice = Prosereflect::Transform::Slice.empty
        expect(slice.empty?).to be true
        expect(slice.open_start).to eq(0)
        expect(slice.open_end).to eq(0)
      end

      it "Slice with content reports correct size" do
        content = Prosereflect::Fragment.new(
          [
            Prosereflect::Text.new(text: "abc"),
          ],
        )
        slice = Prosereflect::Transform::Slice.new(content, 1, 1)

        # content_size = 4 (text "abc" = 3+1), size = 4+1+1 = 6
        expect(slice.size).to eq(6)
        expect(slice.open_start).to eq(1)
        expect(slice.open_end).to eq(1)
      end

      it "Slice equality checks open_start and open_end" do
        content = Prosereflect::Fragment.new([Prosereflect::Text.new(text: "a")])
        slice1 = Prosereflect::Transform::Slice.new(content, 0, 0)
        slice2 = Prosereflect::Transform::Slice.new(content, 1, 0)

        expect(slice1).not_to eq(slice2)
      end

      it "two identical slices are equal" do
        content = Prosereflect::Fragment.new([Prosereflect::Text.new(text: "x")])
        slice1 = Prosereflect::Transform::Slice.new(content, 0, 0)
        slice2 = Prosereflect::Transform::Slice.new(
          Prosereflect::Fragment.new([Prosereflect::Text.new(text: "x")]), 0, 0
        )

        expect(slice1).to eq(slice2)
      end

      it "Slice.empty with open boundaries is not empty" do
        slice = Prosereflect::Transform::Slice.new(
          Prosereflect::Fragment.new([]), 1, 0
        )
        expect(slice.empty?).to be false
      end
    end

    context "with StepMap composition" do
      it "adding an empty map to a non-empty map returns the non-empty map" do
        step_map = Prosereflect::Transform::StepMap.new([[0, 5, 0, 5]])
        empty_map = Prosereflect::Transform::StepMap.empty
        result = step_map.add_map(empty_map)

        expect(result.ranges).to eq([[0, 5, 0, 5]])
      end

      it "adding a non-empty map to an empty map returns the non-empty map" do
        empty_map = Prosereflect::Transform::StepMap.empty
        step_map = Prosereflect::Transform::StepMap.new([[0, 5, 0, 5]])
        result = empty_map.add_map(step_map)

        expect(result.ranges).to eq([[0, 5, 0, 5]])
      end
    end
  end
end
