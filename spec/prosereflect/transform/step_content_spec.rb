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
end
