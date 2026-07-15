# frozen_string_literal: true

require "spec_helper"

# Node#content is declared `collection: true`, so lutaml-model wraps a non-array
# value into an array. Handing it a Fragment therefore yields `[Fragment]` rather
# than the nodes, and node_size then blows up on the Fragment. Steps must rebuild
# documents through Node#copy, which unwraps a Fragment correctly.
RSpec.describe "Transform steps rebuild documents with node content" do # rubocop:disable RSpec/DescribeClass
  def build_doc(text: "hi", attrs: nil)
    paragraph = { "type" => "paragraph", "content" => [{ "type" => "text", "text" => text }] }
    paragraph["attrs"] = attrs if attrs
    Prosereflect::Parser.parse_document("type" => "doc", "content" => [paragraph])
  end

  shared_examples "a step yielding node content" do
    it "puts nodes in content rather than a Fragment" do
      expect(result.doc.content).to all(be_a(Prosereflect::Node))
    end

    it "leaves the document traversable" do
      expect { result.doc.node_size }.not_to raise_error
    end
  end

  describe Prosereflect::Transform::AddMarkStep do
    let(:doc) { build_doc }
    let(:result) do
      described_class.new(0, doc.node_size, Prosereflect::Mark::Bold.new).apply(doc)
    end

    it_behaves_like "a step yielding node content"
  end

  describe Prosereflect::Transform::AddNodeMarkStep do
    let(:doc) { build_doc }
    let(:result) { described_class.new(0, Prosereflect::Mark::Bold.new).apply(doc) }

    it_behaves_like "a step yielding node content"
  end

  describe Prosereflect::Transform::RemoveNodeMarkStep do
    let(:doc) { build_doc }
    let(:result) { described_class.new(0, Prosereflect::Mark::Bold.new).apply(doc) }

    it_behaves_like "a step yielding node content"
  end

  describe Prosereflect::Transform::AttrStep do
    let(:doc) { build_doc(attrs: { "align" => "left" }) }
    let(:result) { described_class.new(0, { "align" => "center" }).apply(doc) }

    it_behaves_like "a step yielding node content"

    it "applies the new attributes" do
      expect(result.doc.content.first.attrs).to eq({ "align" => "center" })
    end
  end

  describe Prosereflect::Transform::ReplaceStep do
    let(:doc) { build_doc(text: "ab") }
    let(:result) do
      slice = Prosereflect::Transform::Slice.new(
        Prosereflect::Fragment.new([Prosereflect::Text.new(text: "X")]),
      )
      described_class.new(2, 3, slice).apply(doc)
    end

    it_behaves_like "a step yielding node content"
  end

  # Node#replace rebuilds ancestors through copy, whose new_attrs defaults to the
  # original's attrs. That object is passed to the constructor, but lutaml-model
  # copies it on assignment, so the rebuilt tree does not share mutable attrs
  # state with the source document.
  describe "attrs isolation between the source and rebuilt trees" do
    let(:doc) { build_doc(text: "ab", attrs: { "align" => "left" }) }
    let(:rebuilt) { doc.replace(2, 3, [Prosereflect::Text.new(text: "X")]) }

    it "does not share the attrs hash" do
      expect(rebuilt.content.first.attrs).not_to be(doc.content.first.attrs)
    end

    it "does not leak a mutation of the rebuilt tree back to the source" do
      rebuilt.content.first.attrs["align"] = "center"

      expect(doc.content.first.attrs["align"]).to eq("left")
    end

    it "does not share nested attrs values" do
      nested = build_doc(text: "ab", attrs: { "style" => { "color" => "red" } })
      copy = nested.replace(2, 3, [Prosereflect::Text.new(text: "X")])
      copy.content.first.attrs["style"]["color"] = "blue"

      expect(nested.content.first.attrs["style"]["color"]).to eq("red")
    end
  end
end
