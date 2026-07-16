# frozen_string_literal: true

require "spec_helper"

# Under the corrected model a text node costs exactly its character count, so
# splitting or merging text is position-neutral and a mark step (which must not
# move content) is representable. These lock that invariant.
RSpec.describe "Text node_size equals character length" do # rubocop:disable RSpec/DescribeClass
  def doc_with_text(text)
    Prosereflect::Parser.parse_document(
      "type" => "doc",
      "content" => [
        { "type" => "paragraph", "content" => [{ "type" => "text", "text" => text }] },
      ],
    )
  end

  it "sizes a text node as its length" do
    expect(Prosereflect::Text.new(text: "abcd").node_size).to eq(4)
  end

  it "sizes an empty text node as zero" do
    expect(Prosereflect::Text.new(text: "").node_size).to eq(0)
  end

  it "preserves total node_size when a text node is split into differently-marked runs" do
    doc = doc_with_text("abcd")
    # Bold "X" so merge_adjacent_text does NOT rejoin it with the unmarked
    # neighbours. An unmarked "X" would merge back to one node "aXcd" and mask
    # the split, which is why the naive version of this test passes even on the
    # broken code (Codex caught that).
    marked = Prosereflect::Text.new(text: "X", marks: [{ "type" => "bold" }])
    slice = Prosereflect::Transform::Slice.new(Prosereflect::Fragment.new([marked]))
    # Replace "b" (positions 3..4) with a bold "X": same length.
    result = Prosereflect::Transform::ReplaceStep.new(3, 4, slice).apply(doc)

    expect(result).to be_ok
    expect(result.doc.text_content).to eq("aXcd")
    # Genuinely split into three nodes, not remerged.
    expect(result.doc.content.first.content.map(&:text)).to eq(%w[a X cd])
    # Splitting one text node into three is size-neutral only when text = length.
    expect(result.doc.node_size).to eq(doc.node_size)
  end

  # Asserts only the DELTA that get_map encodes, which the +1 skew corrupted
  # (it read 0 for a real -1). It does NOT assert that StepMap#map maps arbitrary
  # positions correctly; that is a separate, pre-existing concern (see "Known
  # pre-existing bugs" in the plan) and is out of scope here.
  it "makes get_map's encoded delta equal the real document size change" do
    doc = doc_with_text("Hello")
    slice = Prosereflect::Transform::Slice.new(
      Prosereflect::Fragment.new([Prosereflect::Text.new(text: "XY")]),
    )
    # Replace "ell" (3 chars) with "XY" (2 chars): true delta -1.
    step = Prosereflect::Transform::ReplaceStep.new(3, 6, slice)
    actual_delta = step.apply(doc).doc.node_size - doc.node_size
    map_delta = step.get_map.ranges.first[3] - step.get_map.ranges.first[2]

    expect(actual_delta).to eq(-1)
    expect(map_delta).to eq(actual_delta)
  end

  # Empty text now has node_size 0, so a mid-content empty text node is a
  # zero-width position. It does not shift its siblings (asserted here). Accepted
  # consequence, confirmed with Codex: a zero-size node is STILL VISITED by
  # nodes_between/descendants, at the same position as the following sibling
  # (for [ab, "", cd] the empty node reports at position 3, the "cd" position).
  # That is coherent (it occupies no width) and empty text is degenerate anyway
  # (merge_adjacent_text drops it), so it is not guarded against, only
  # acknowledged.
  it "gives a mid-content empty text node zero width" do
    paragraph = Prosereflect::Paragraph.new(
      type: "paragraph",
      content: [
        Prosereflect::Text.new(text: "ab"),
        Prosereflect::Text.new(text: ""),
        Prosereflect::Text.new(text: "cd"),
      ],
    )
    # 1 (para token) + 2 + 0 + 2 = 5.
    expect(paragraph.node_size).to eq(5)
  end
end
