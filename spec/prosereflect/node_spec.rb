# frozen_string_literal: true

require "spec_helper"

RSpec.describe Prosereflect::Node do
  describe "initialization" do
    it "initializes with empty data" do
      node = described_class.new
      expect(node.type).to be_nil
      expect(node.attrs).to be_nil
      expect(node.content).to be_nil
      expect(node.marks).to be_nil
    end

    # TODO: Update to lutaml-model
    it "initializes with provided data" do
      data = {
        "type" => "test_node",
        "attrs" => { "key" => "value" },
        "marks" => [{ "type" => "bold" }],
      }
      node = described_class.new(data)
      expect(node.type).to eq("test_node")
      expect(node.attrs).to eq({ "key" => "value" })
      expect(node.marks).to eq([{ "type" => "bold" }])
    end
  end

  describe "#parse_content" do
    it "returns empty array for nil content" do
      node = described_class.new
      expect(node.parse_content(nil)).to eq([])
    end

    it "parses content items using Parser" do
      content_data = [
        { "type" => "text", "text" => "Hello" },
        { "type" => "hard_break" },
      ]

      node = described_class.new
      parsed_content = node.parse_content(content_data)

      expect(parsed_content.size).to eq(2)
      expect(parsed_content[0]).to be_a(Prosereflect::Text)
      expect(parsed_content[1]).to be_a(Prosereflect::HardBreak)
    end
  end

  describe "#marks= reconstruction" do
    it "builds hash marks without resolving unrelated Ruby constants" do
      node = Prosereflect::Text.new(text: "x")
      node.marks = [{ "type" => "string" }]

      expect(node.raw_marks.first).to be_a(Prosereflect::Mark::Base)
      expect(node.raw_marks.map(&:type)).to eq(%w[string])
    end

    it "still builds known mark subclasses" do
      node = Prosereflect::Text.new(text: "x")
      node.marks = [{ "type" => "bold" }]

      expect(node.raw_marks.first).to be_a(Prosereflect::Mark::Bold)
    end
  end

  describe "#to_h" do
    it "creates a hash representation with basic properties" do
      node = described_class.new({ "type" => "test_node" })
      hash = node.to_hash

      expect(hash).to be_a(Hash)
      expect(hash["type"]).to eq("test_node")
    end

    it "includes attrs when present" do
      node = described_class.new(
        type: Prosereflect::Text.new(text: "Hello"),
        attrs: [Prosereflect::Attribute::Href.new("https://example.com")],
      )

      hash = node.to_hash
      expect(hash["attrs"]).to eq([{ "href" => "https://example.com" }])
    end

    it "includes marks when present" do
      node = described_class.new(
        type: Prosereflect::Text.new(text: "Hello"),
        marks: [Prosereflect::Mark::Bold.new],
      )

      hash = node.to_hash
      expect(hash["marks"]).to eq([{ "type" => "bold" }])
    end

    it "includes content when present" do
      node = described_class.new({
                                   "type" => "test_node",
                                   "content" => [{ "type" => "text",
                                                   "text" => "Hello" }],
                                 })

      hash = node.to_hash
      expect(hash["content"]).to be_an(Array)
      expect(hash["content"][0]["type"]).to eq("text")
    end
  end

  describe "#add_child" do
    it "adds a child node to content" do
      parent = described_class.new({ "type" => "parent" })
      child = described_class.new({ "type" => "child" })

      parent.add_child(child)

      expect(parent.content.size).to eq(1)
      expect(parent.content[0]).to eq(child)
    end

    it "returns the added child" do
      parent = described_class.new({ "type" => "parent" })
      child = described_class.new({ "type" => "child" })

      result = parent.add_child(child)

      expect(result).to eq(child)
    end
  end

  describe "#find_first" do
    let(:node) do
      root = described_class.new({ "type" => "root" })
      para = Prosereflect::Paragraph.new({ "type" => "paragraph" })
      text = Prosereflect::Text.new({ "type" => "text", "text" => "Hello" })

      para.add_child(text)
      root.add_child(para)
      root
    end

    it "returns self if type matches" do
      result = node.find_first("root")
      expect(result).to eq(node)
    end

    it "finds a child node by type" do
      result = node.find_first("paragraph")
      expect(result).to be_a(Prosereflect::Paragraph)
    end

    it "finds a nested node by type" do
      result = node.find_first("text")
      expect(result).to be_a(Prosereflect::Text)
    end

    it "returns nil if no matching node is found" do
      result = node.find_first("nonexistent")
      expect(result).to be_nil
    end
  end

  describe ".create" do
    it "creates a simple node" do
      node = described_class.create("test_node")

      expected = {
        "type" => "test_node",
      }

      expect(node.to_h).to eq(expected)
    end

    it "creates a node with attributes" do
      node = described_class.create("test_node", {
                                      "key" => "value",
                                      "number" => 42,
                                      "flag" => true,
                                    })

      expected = {
        "type" => "test_node",
        "attrs" => {
          "key" => "value",
          "number" => 42,
          "flag" => true,
        },
      }

      expect(node.to_h).to eq(expected)
    end
  end

  describe "node structure" do
    it "creates a node with content" do
      node = described_class.create("parent")
      node.add_child(Prosereflect::Text.create("First child"))
      node.add_child(Prosereflect::Text.create("Second child"))

      expected = {
        "type" => "parent",
        "content" => [
          {
            "type" => "text",
            "text" => "First child",
          },
          {
            "type" => "text",
            "text" => "Second child",
          },
        ],
      }

      expect(node.to_h).to eq(expected)
    end

    it "creates a node with complex content" do
      node = described_class.create("root")

      # Add a paragraph with formatted text
      para = Prosereflect::Paragraph.create
      para.add_child(Prosereflect::Text.create("Bold", [Prosereflect::Mark::Bold.create]))
      para.add_child(Prosereflect::Text.create(" and "))
      para.add_child(Prosereflect::Text.create("italic", [Prosereflect::Mark::Italic.create]))
      node.add_child(para)

      # Add a list
      list = Prosereflect::BulletList.create
      list_item = Prosereflect::ListItem.create
      list_item.add_child(Prosereflect::Paragraph.create)
      list_item.content.first.add_child(Prosereflect::Text.create("List item"))
      list.add_child(list_item)
      node.add_child(list)

      expected = {
        "type" => "root",
        "content" => [
          {
            "type" => "paragraph",
            "content" => [
              {
                "type" => "text",
                "text" => "Bold",
                "marks" => [{ "type" => "bold" }],
              },
              {
                "type" => "text",
                "text" => " and ",
              },
              {
                "type" => "text",
                "text" => "italic",
                "marks" => [{ "type" => "italic" }],
              },
            ],
          },
          {
            "type" => "bullet_list",
            "attrs" => {
              "bullet_style" => nil,
            },
            "content" => [
              {
                "type" => "list_item",
                "content" => [
                  {
                    "type" => "paragraph",
                    "content" => [
                      {
                        "type" => "text",
                        "text" => "List item",
                      },
                    ],
                  },
                ],
              },
            ],
          },
        ],
      }

      expect(node.to_h).to eq(expected)
    end
  end

  describe "node operations" do
    describe "#add_child" do
      it "adds a child node and returns it" do
        parent = described_class.create("parent")
        child = Prosereflect::Text.create("Child node")

        result = parent.add_child(child)
        expect(result).to eq(child)
        expect(parent.content).to eq([child])
      end

      it "maintains child order" do
        parent = described_class.create("parent")
        first = Prosereflect::Text.create("First")
        second = Prosereflect::Text.create("Second")
        third = Prosereflect::Text.create("Third")

        parent.add_child(first)
        parent.add_child(second)
        parent.add_child(third)

        expect(parent.content).to eq([first, second, third])
        expect(parent.text_content).to eq("FirstSecondThird")
      end
    end

    describe "#find_first" do
      let(:node) do
        root = described_class.create("root")
        para = Prosereflect::Paragraph.create
        text = Prosereflect::Text.create("Hello")
        para.add_child(text)
        root.add_child(para)
        root
      end

      it "finds nodes by type" do
        expect(node.find_first("root")).to eq(node)
        expect(node.find_first("paragraph")).to be_a(Prosereflect::Paragraph)
        expect(node.find_first("text")).to be_a(Prosereflect::Text)
        expect(node.find_first("nonexistent")).to be_nil
      end
    end

    describe "#find_all" do
      let(:node) do
        root = described_class.create("root")

        # First paragraph
        para1 = Prosereflect::Paragraph.create
        para1.add_child(Prosereflect::Text.create("First"))
        root.add_child(para1)

        # Second paragraph
        para2 = Prosereflect::Paragraph.create
        para2.add_child(Prosereflect::Text.create("Second"))
        root.add_child(para2)

        root
      end

      it "finds all nodes of a type" do
        expect(node.find_all("paragraph").size).to eq(2)
        expect(node.find_all("text").size).to eq(2)
        expect(node.find_all("nonexistent")).to eq([])
      end
    end

    describe "#find_children" do
      let(:node) do
        root = described_class.create("root")
        root.add_child(Prosereflect::Paragraph.create)
        root.add_child(Prosereflect::Table.create)
        root.add_child(Prosereflect::Paragraph.create)
        root
      end

      it "finds direct children by class" do
        paragraphs = node.find_children(Prosereflect::Paragraph)
        expect(paragraphs.size).to eq(2)
        expect(paragraphs).to all(be_a(Prosereflect::Paragraph))

        tables = node.find_children(Prosereflect::Table)
        expect(tables.size).to eq(1)
        expect(tables.first).to be_a(Prosereflect::Table)
      end
    end

    describe "#text_content" do
      it "concatenates text from all children" do
        root = described_class.create("root")

        para = Prosereflect::Paragraph.create
        para.add_child(Prosereflect::Text.create("Hello"))
        para.add_child(Prosereflect::HardBreak.create)
        para.add_child(Prosereflect::Text.create("World"))
        root.add_child(para)

        expect(root.text_content).to eq("Hello\nWorld")
      end

      it "returns empty string for empty node" do
        node = described_class.create("empty")
        expect(node.text_content).to eq("")
      end
    end
  end

  describe "serialization" do
    it "serializes a node with all properties" do
      node = described_class.create("test_node", {
                                      "key" => "value",
                                      "number" => 42,
                                    })

      text = Prosereflect::Text.create("Content", [
                                         Prosereflect::Mark::Bold.create,
                                         Prosereflect::Mark::Link.create({ "href" => "https://example.com" }),
                                       ])

      node.add_child(text)

      expected = {
        "type" => "test_node",
        "attrs" => {
          "key" => "value",
          "number" => 42,
        },
        "content" => [
          {
            "type" => "text",
            "text" => "Content",
            "marks" => [
              { "type" => "bold" },
              {
                "type" => "link",
                "attrs" => {
                  "href" => "https://example.com",
                },
              },
            ],
          },
        ],
      }

      expect(node.to_h).to eq(expected)
    end

    it "omits optional properties when empty" do
      node = described_class.create("test_node")

      expected = {
        "type" => "test_node",
      }

      expect(node.to_h).to eq(expected)
    end
  end

  describe "#node_size" do
    it "returns 1 for empty node" do
      node = described_class.create("empty")
      expect(node.node_size).to eq(1)
    end

    it "includes text children" do
      node = described_class.create("parent")
      node.add_child(Prosereflect::Text.create("hello"))
      # 1 (parent) + 5 (text "hello") = 6
      expect(node.node_size).to eq(6)
    end

    it "sums multiple children" do
      node = described_class.create("parent")
      node.add_child(Prosereflect::Text.create("ab"))
      node.add_child(Prosereflect::Text.create("cd"))
      # 1 (parent) + 2 ("ab") + 2 ("cd") = 5
      expect(node.node_size).to eq(5)
    end

    it "handles deeply nested content" do
      doc = Prosereflect::Document.create
      para = Prosereflect::Paragraph.create
      para.add_child(Prosereflect::Text.create("hi"))
      doc.add_child(para)
      # 1 (doc) + 1 (para) + 2 (text "hi") = 4
      expect(doc.node_size).to eq(4)
    end
  end

  describe "#text?" do
    it "returns false for regular nodes" do
      expect(described_class.create("node").text?).to be false
      expect(Prosereflect::Paragraph.create.text?).to be false
      expect(Prosereflect::Document.create.text?).to be false
    end

    it "returns true for Text nodes" do
      expect(Prosereflect::Text.create("hello").text?).to be true
    end
  end

  describe "#cut" do
    it "returns self for full range" do
      node = described_class.create("node")
      # `be`, not `eq`: the full range is documented to hand back the receiver
      # itself rather than a copy, so callers may get an alias. Value equality
      # would pass even if that changed.
      expect(node.cut(0, 1)).to be(node)
    end

    it "returns self for default range" do
      node = described_class.create("node")
      expect(node.cut).to be(node)
    end

    it "returns copy with subset of content" do
      node = described_class.create("parent")
      node.add_child(Prosereflect::Text.create("first"))
      node.add_child(Prosereflect::Text.create("second"))
      cut_node = node.cut(1, 6) # tree-local: "first" spans [1, 6)
      expect(cut_node).not_to eq(node)
      expect(cut_node.content.map(&:text)).to eq(%w[first])
    end

    it "cuts a partial range out of a text child" do
      node = described_class.create("parent")
      node.add_child(Prosereflect::Text.create("abcd"))
      # Tree-local: the parent's token is at 0, so "abcd" spans [1,5) and its
      # characters sit at 1,2,3,4. The range [2,4) is "bc".
      expect(node.cut(2, 4).content.map(&:text)).to eq(%w[bc])
    end

    it "is the exact complement of replace over the same range" do
      node = described_class.create("parent")
      node.add_child(Prosereflect::Text.create("abcd"))
      # cut keeps what replace removes. These two must never disagree about
      # what [2,4) means.
      expect(node.cut(2, 4).content.map(&:text)).to eq(%w[bc])
      expect(node.replace(2, 4, []).content.map(&:text)).to eq(%w[ad])
    end

    it "cuts a partial range through a nested child" do
      doc = Prosereflect::Parser.parse_document(
        "type" => "doc",
        "content" => [
          { "type" => "paragraph", "content" => [{ "type" => "text", "text" => "abc" }] },
          { "type" => "paragraph", "content" => [{ "type" => "text", "text" => "xyz" }] },
        ],
      )
      # para1 spans [1,5). The range [2,4) is "ab" inside it, and the second
      # paragraph lies wholly outside.
      cut = doc.cut(2, 4)

      expect(cut.content.map(&:type)).to eq(%w[paragraph])
      expect(cut.text_content).to eq("ab")
    end

    it "returns a node with no content for a zero-width cut" do
      node = described_class.create("parent")
      node.add_child(Prosereflect::Text.create("abcd"))
      # No empty-text residue: a zero-width cut keeps nothing.
      expect(node.cut(2, 2).content.to_a).to be_empty
    end

    it "gives the result its own content array when a side needs no trimming" do
      node = described_class.create("parent")
      node.add_child(Prosereflect::Text.create("abcd"))
      # [1, node_size) needs neither a head nor a tail trim, but it is not the
      # full range, so it must still be a copy. Returning self here would let a
      # caller mutate the original through the cut result.
      cut_node = node.cut(1, node.node_size)

      expect(cut_node).not_to be(node)
      expect(cut_node.content).not_to be(node.content)
      cut_node.add_child(Prosereflect::Text.create("x"))
      expect(node.text_content).to eq("abcd")
    end

    it "shares untouched child nodes with the receiver, as replace does" do
      node = described_class.create("parent")
      node.add_child(Prosereflect::Text.create("ab"))
      node.add_child(Prosereflect::Text.create("cd"))
      # Structural sharing is the model this library already uses: splice carries
      # untouched children across by reference, so replace and cut both share
      # them. Documented rather than guarded, because the guarantee cut offers is
      # a private content array, NOT deep independence. Callers must not mutate a
      # child of a cut result in place.
      cut_node = node.cut(1, 3)

      expect(cut_node.content.first).to be(node.content.first)
      expect(node.replace(4, 5, []).content.first).to be(node.content.first)
    end
  end

  describe "#nodes_between" do
    it "visits a sibling when an earlier sibling is entirely before the range" do
      doc = Prosereflect::Parser.parse_document(
        "type" => "doc",
        "content" => [
          { "type" => "paragraph", "content" => [{ "type" => "text", "text" => "ab" }] },
          { "type" => "paragraph", "content" => [{ "type" => "text", "text" => "cd" }] },
        ],
      )
      # nodes_between takes content offsets, so this document's range is [0,6):
      # para1 occupies [0,3), para2 [3,6). Asking for [4,6) lands wholly inside
      # para2, so para1 is skipped. Skipping must still advance `pos`, or every
      # later sibling is measured from a stale offset and the walk yields
      # nothing. (The positions it reports back are tree positions, hence 4/5.)
      visited = []
      doc.nodes_between(4, 6) { |node, pos| visited << [node.type, pos] }

      expect(visited).to eq([["paragraph", 4], ["text", 5]])
    end

    it "yields children in range" do
      node = described_class.create("parent")
      t1 = Prosereflect::Text.create("ab")
      t2 = Prosereflect::Text.create("cd")
      node.add_child(t1)
      node.add_child(t2)

      visited = []
      node.nodes_between(0, 6) { |n, _pos, _i| visited << n }
      expect(visited).to include(t1)
    end

    it "does not yield for empty range" do
      node = described_class.create("parent")
      visited = []
      node.nodes_between(0, 0) { |n| visited << n }
      expect(visited).to be_empty
    end
  end

  describe "#descendants" do
    it "iterates over all descendants" do
      doc = Prosereflect::Document.create
      para = Prosereflect::Paragraph.create
      text = Prosereflect::Text.create("hello")
      para.add_child(text)
      doc.add_child(para)

      visited = []
      doc.descendants { |n, _pos, _i| visited << n }
      expect(visited).to include(para)
    end
  end

  describe "position-targeted node access" do
    # doc > [ paragraph > text "Hello", paragraph > text "Bye" ]
    # doc token @0; para1 token @1 (size 6, spans [1,7)); para2 token @7 (size 4, spans [7,11)).
    let(:doc) do
      Prosereflect::Parser.parse_document(
        "type" => "doc",
        "content" => [
          { "type" => "paragraph", "content" => [{ "type" => "text", "text" => "Hello" }] },
          { "type" => "paragraph", "content" => [{ "type" => "text", "text" => "Bye" }] },
        ],
      )
    end

    describe "#node_at" do
      it "returns the node whose token sits at the position" do
        expect(doc.node_at(7).type).to eq("paragraph")
        expect(doc.node_at(7).content.first.text).to eq("Bye")
      end

      it "returns self for position 0" do
        expect(doc.node_at(0)).to be(doc)
      end

      it "returns the text node at its start position" do
        # para1 token @1, its text child starts at @2
        expect(doc.node_at(2).text).to eq("Hello")
      end
    end

    describe "#map_node_at" do
      it "rebuilds only the targeted nested node" do
        result = doc.map_node_at(7) { |n| n.copy(n.content, { "align" => "center" }) }

        expect(result.content[1].attrs).to eq({ "align" => "center" })
        expect(result.content[0].attrs).to be_nil
        expect(result.node_size).to eq(doc.node_size)
      end

      it "does not mutate the receiver" do
        doc.map_node_at(7) { |n| n.copy(n.content, { "align" => "center" }) }
        expect(doc.content[1].attrs).to be_nil
      end

      it "returns an equivalent tree when the position hits no node token" do
        # a position strictly inside "Hello" characters is not a node boundary
        expect(doc.map_node_at(4) { |n| n.with_marks([Prosereflect::Mark::Bold.new]) }.to_h)
          .to eq(doc.to_h)
      end
    end
  end

  describe "#update_marks" do
    let(:bold) { Prosereflect::Mark::Bold.new }

    def para(*children)
      p = Prosereflect::Paragraph.new
      p.content = children
      p
    end

    def doc_with(*paragraphs)
      d = Prosereflect::Document.new
      d.content = paragraphs
      d
    end

    it "marks only the covered characters of a text node, splitting it" do
      # para token @1, "Hello" spans [2,7); mark "ell" = doc [3,6)
      doc = doc_with(para(Prosereflect::Text.new(text: "Hello")))
      result = doc.update_marks(3, 6) { |marks| bold.add_to_set(marks) }

      pieces = result.content[0].content
      expect(pieces.map(&:text)).to eq(%w[H ell o])
      expect(pieces.map { |t| (t.raw_marks || []).map(&:type) }).to eq([[], %w[bold], []])
      expect(result.node_size).to eq(doc.node_size)
    end

    it "marks across adjacent text children and merges equal-mark runs" do
      # "ab" then bold "cd"; marking the whole run dedups bold and merges to one node
      doc = doc_with(para(
                       Prosereflect::Text.new(text: "ab"),
                       Prosereflect::Text.new(text: "cd", marks: [{ "type" => "bold" }]),
                     ))
      # para @1: "ab" [2,4), "cd" [4,6); mark [2,6)
      result = doc.update_marks(2, 6) { |marks| bold.add_to_set(marks) }

      pieces = result.content[0].content
      expect(pieces.map(&:text)).to eq(%w[abcd])
      expect((pieces.first.raw_marks || []).map(&:type)).to eq(%w[bold])
    end

    it "removing a mark normalizes a newly-equal boundary into one node" do
      doc = doc_with(para(
                       Prosereflect::Text.new(text: "ab"),
                       Prosereflect::Text.new(text: "cd", marks: [{ "type" => "bold" }]),
                     ))
      # remove bold from "cd" only ([4,6)); result "ab" + "cd" both unmarked -> "abcd"
      result = doc.update_marks(4, 6) { |marks| bold.remove_from_set(marks) }

      expect(result.content[0].content.map(&:text)).to eq(%w[abcd])
      expect(result.content[0].content.first.raw_marks || []).to eq([])
    end

    it "leaves untouched siblings outside the range unmerged" do
      doc = doc_with(para(
                       Prosereflect::Text.new(text: "aa"),
                       Prosereflect::Text.new(text: "bb"),
                       Prosereflect::Text.new(text: "cc"),
                     ))
      # para @1: "aa" [2,4), "bb" [4,6), "cc" [6,8); mark only "aa"
      result = doc.update_marks(2, 4) { |marks| bold.add_to_set(marks) }

      # "bb" and "cc" sit outside the edit, so the step must not restructure them.
      expect(result.content[0].content.map(&:text)).to eq(%w[aa bb cc])
    end

    it "keeps a text node's attrs when the mark splits it" do
      doc = doc_with(para(Prosereflect::Text.new(text: "Hello", attrs: { "lang" => "en" })))
      result = doc.update_marks(3, 6) { |marks| bold.add_to_set(marks) }

      pieces = result.content[0].content
      expect(pieces.map(&:text)).to eq(%w[H ell o])
      expect(pieces.map(&:attrs)).to all(eq({ "lang" => "en" }))
    end

    it "does not mutate the receiver" do
      doc = doc_with(para(Prosereflect::Text.new(text: "Hello")))
      doc.update_marks(3, 6) { |marks| bold.add_to_set(marks) }
      expect(doc.content[0].content.first.text).to eq("Hello")
      expect(doc.content[0].content.first.raw_marks).to be_nil
    end

    it "returns self-equivalent output for an empty range" do
      doc = doc_with(para(Prosereflect::Text.new(text: "Hello")))
      expect(doc.update_marks(3, 3) { |marks| bold.add_to_set(marks) }.to_h).to eq(doc.to_h)
    end
  end

  describe "#eq?" do
    it "returns true for structurally equal nodes" do
      n1 = described_class.create("node")
      n2 = described_class.create("node")
      expect(n1.eq?(n2)).to be true
    end

    it "returns false for different types" do
      n1 = described_class.create("a")
      n2 = described_class.create("b")
      expect(n1.eq?(n2)).to be false
    end
  end

  describe "#copy" do
    it "creates a shallow copy with same type and attrs" do
      node = described_class.create("node", "key" => "val")
      copy = node.copy
      expect(copy.to_h).to eq(node.to_h)
      expect(copy).not_to equal(node)
    end

    it "creates copy with new content" do
      node = described_class.create("parent")
      copy = node.copy([Prosereflect::Text.create("new")])
      expect(copy.content.length).to eq(1)
      expect(node.content).to be_empty
    end
  end

  describe "#copy preserves typed attributes" do
    it "keeps a heading's level" do
      heading = Prosereflect::Parser.parse_node(
        "type" => "heading", "attrs" => { "level" => 2 },
        "content" => [{ "type" => "text", "text" => "x" }]
      )
      expect(heading.copy(heading.content).to_h["attrs"]).to eq({ "level" => 2 })
    end

    it "keeps an image's src and alt" do
      image = Prosereflect::Parser.parse_node("type" => "image", "attrs" => { "src" => "s", "alt" => "a" })
      expect(image.copy(image.content).to_h["attrs"]).to eq({ "src" => "s", "alt" => "a" })
    end

    it "keeps a code_block's language" do
      cb = Prosereflect::Parser.parse_node(
        "type" => "code_block", "attrs" => { "language" => "ruby" },
        "content" => [{ "type" => "text", "text" => "x" }]
      )
      expect(cb.copy(cb.content).to_h["attrs"]).to eq({ "language" => "ruby" })
    end

    it "keeps a blockquote's citation" do
      bq = Prosereflect::Parser.parse_node(
        "type" => "blockquote", "attrs" => { "citation" => "src" },
        "content" => [{ "type" => "paragraph", "content" => [{ "type" => "text", "text" => "x" }] }]
      )
      expect(bq.copy(bq.content).to_h["attrs"]).to eq({ "citation" => "src" })
    end

    it "keeps a horizontal_rule's style, width and thickness" do
      hr = Prosereflect::Parser.parse_node(
        "type" => "horizontal_rule",
        "attrs" => { "style" => "solid", "width" => "2px", "thickness" => 1 },
      )
      expect(hr.copy(hr.content).to_h["attrs"]).to eq({ "style" => "solid", "width" => "2px", "thickness" => 1 })
    end

    it "keeps a table_header's scope, abbr and colspan" do
      th = Prosereflect::Parser.parse_node(
        "type" => "table_header", "attrs" => { "scope" => "col", "abbr" => "x", "colspan" => 2 },
        "content" => [{ "type" => "paragraph", "content" => [{ "type" => "text", "text" => "x" }] }]
      )
      expect(th.copy(th.content).to_h["attrs"]).to eq({ "scope" => "col", "abbr" => "x", "colspan" => 2 })
    end

    it "keeps a code_block_wrapper's line_numbers" do
      cbw = Prosereflect::Parser.parse_node(
        "type" => "code_block_wrapper", "attrs" => { "line_numbers" => true },
        "content" => []
      )
      expect(cbw.copy(cbw.content).to_h["attrs"]).to eq({ "line_numbers" => true })
    end
  end

  describe "#with_marks" do
    it "rebuilds a non-text node with new marks, preserving content and attrs" do
      para = Prosereflect::Paragraph.new(attrs: { "align" => "left" })
      para.content = [Prosereflect::Text.new(text: "x")]
      result = para.with_marks([Prosereflect::Mark::Bold.new])

      expect(result.raw_marks.map(&:type)).to eq(%w[bold])
      expect(result.attrs).to eq({ "align" => "left" })
      expect(result.content.first.text).to eq("x")
      expect(result).not_to be(para)
    end

    it "does not mutate the receiver" do
      para = Prosereflect::Paragraph.new
      para.with_marks([Prosereflect::Mark::Bold.new])
      expect(para.raw_marks).to be_nil
    end
  end
end
