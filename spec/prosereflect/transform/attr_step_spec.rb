# frozen_string_literal: true

require "spec_helper"

RSpec.describe Prosereflect::Transform::AttrStep do
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

  it "sets attrs on a node that has none (was a nil.merge crash)" do
    doc = two_paras
    result = described_class.new(3, { "align" => "center" }).apply(doc)

    expect(result).to be_ok
    expect(result.doc.content[1].attrs).to eq({ "align" => "center" })
  end

  it "reaches a nested node instead of only top-level children" do
    doc = two_paras
    result = described_class.new(3, { "align" => "center" }).apply(doc)

    expect(result.doc.content[0].attrs).to be_nil
    expect(result.doc.node_size).to eq(doc.node_size)
  end

  it "inverts to restore the previous attrs" do
    doc = Prosereflect::Parser.parse_document(
      "type" => "doc",
      "content" => [
        { "type" => "paragraph", "content" => [{ "type" => "text", "text" => "a" }] },
        { "type" => "paragraph", "attrs" => { "align" => "left" },
          "content" => [{ "type" => "text", "text" => "b" }] },
      ],
    )
    step = described_class.new(3, { "align" => "center" })
    inverse = step.invert(doc)
    applied = step.apply(doc).doc
    restored = inverse.apply(applied).doc

    expect(restored.content[1].attrs).to eq({ "align" => "left" })
  end

  it "inverts an added attr back to absent" do
    doc = two_paras # para2 has no attrs
    step = described_class.new(3, { "align" => "center" })
    inverse = step.invert(doc)
    applied = step.apply(doc).doc
    restored = inverse.apply(applied).doc

    # The added attr is gone; a node with no attributes serializes without an
    # attrs key regardless of whether the store is nil or an empty hash.
    expect(restored.content[1].to_h).not_to have_key("attrs")
  end

  it "preserves a targeted text node's string" do
    # doc @0; paragraph token @1; text "abc" spans [2,5)
    doc = Prosereflect::Parser.parse_document(
      "type" => "doc",
      "content" => [{ "type" => "paragraph", "content" => [{ "type" => "text", "text" => "abc" }] }],
    )
    result = described_class.new(2, { "foo" => "bar" }).apply(doc)

    text = result.doc.content[0].content[0]
    expect(text.text).to eq("abc")
    expect(result.doc.node_size).to eq(doc.node_size)
  end

  it "changes a typed attribute on an image, re-deriving it" do
    # doc @0; paragraph token @1; image token @2
    doc = Prosereflect::Parser.parse_document(
      "type" => "doc",
      "content" => [{ "type" => "paragraph",
                      "content" => [{ "type" => "image", "attrs" => { "src" => "s", "alt" => "a" } }] }],
    )
    result = described_class.new(2, { "src" => "new", "alt" => "a" }).apply(doc)

    expect(result).to be_ok
    expect(result.doc.content[0].content[0].to_h["attrs"]).to eq({ "src" => "new", "alt" => "a" })
  end

  it "fails when attrs is not a hash (malformed input)" do
    doc = Prosereflect::Parser.parse_document(
      "type" => "doc",
      "content" => [{ "type" => "paragraph", "content" => [{ "type" => "text", "text" => "x" }] }],
    )
    expect(described_class.new(1, nil).apply(doc)).not_to be_ok
  end

  it "fails at a position one past the last node token" do
    doc = two_paras
    expect(described_class.new(doc.node_size, { "align" => "center" }).apply(doc)).not_to be_ok
    expect(described_class.new(doc.node_size - 1, { "align" => "center" }).apply(doc)).to be_ok
  end

  it "rejects a non-integer position at parse time" do
    expect do
      described_class.from_json(nil, { "pos" => "3", "attrs" => { "align" => "center" } })
    end.to raise_error(ArgumentError, /pos/)
  end
end
