# frozen_string_literal: true

require "spec_helper"

RSpec.describe Prosereflect::Transform::DocAttrStep do
  def plain_doc
    Prosereflect::Parser.parse_document(
      "type" => "doc",
      "content" => [{ "type" => "paragraph", "content" => [{ "type" => "text", "text" => "a" }] }],
    )
  end

  it "sets an attr on a document that has none (was a nil.merge crash)" do
    result = described_class.new({ "title" => "T" }).apply(plain_doc)

    expect(result).to be_ok
    expect(result.doc.attrs).to eq({ "title" => "T" })
  end

  it "inverts a document that has no attrs without raising" do
    doc = plain_doc
    step = described_class.new({ "title" => "T" })

    # get_old_doc_attrs reads doc.attrs, which is nil here.
    expect { step.invert(doc) }.not_to raise_error
    inverse = step.invert(doc)
    expect(inverse.apply(step.apply(doc).doc)).to be_ok
  end

  it "restores a replaced attr" do
    doc = Prosereflect::Parser.parse_document(
      "type" => "doc", "attrs" => { "title" => "old" },
      "content" => [{ "type" => "paragraph", "content" => [{ "type" => "text", "text" => "a" }] }]
    )
    step = described_class.new({ "title" => "new" })
    restored = step.invert(doc).apply(step.apply(doc).doc).doc

    expect(restored.attrs["title"]).to eq("old")
  end

  it "leaves no stray position keys in its JSON" do
    expect(described_class.new({ "title" => "T" }).to_json)
      .to eq({ "stepType" => "setDocAttr", "attrs" => { "title" => "T" } })
  end
end
