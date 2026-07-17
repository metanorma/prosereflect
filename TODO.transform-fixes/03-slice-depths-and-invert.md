# PR 03: Slice open depths, invert round-trip, and block joining

**Size:** large. **Depends on:** the [06](06-prosemirror-position-parity.md) decision (01 is done).

Grouped because all three symptoms are one missing feature. `Slice` carries
`open_start` and `open_end`, and nothing acts on them. `invert` needs to cut a
range into a slice with correct depths; joining needs to fit those depths back
together. Fixing one without the other means building half the machinery twice.

## Symptom 1: `invert` does not round-trip

`lib/prosereflect/transform/replace_step.rb:118`

```ruby
def content_between(doc, from, to)      # :118
  result = []
  doc.nodes_between(from, to) { |node| result << node }
  Fragment.new(result)
end
```

`nodes_between` yields at every depth, so this collects **whole visited nodes**
instead of cutting out the removed range. Deleting `"ell"` from `"Hello"` builds an
inverse whose slice carries the entire `Paragraph("Hello")`. Re-applying nests a
paragraph inside a paragraph:

```
doc:           "Hello"
delete 3..6 -> "Ho"
invert, apply -> "HHelloo"     (expected "Hello")
```

PR #13 already fixed `invert`'s **endpoint arithmetic** (`@from + slice.size`),
which used to land one past the end. The endpoints are right now. The captured
content is still wrong. That is this bug.

Current spec asserts the wrong behaviour on purpose:

```ruby
it "does not round-trip: the inverse re-inserts whole visited nodes" do
  expect(restored.doc.text_content).to eq("HHelloo")
  expect(restored.doc.text_content).not_to eq(doc.text_content)
end
```

## Symptom 2: a cross-block range does not join the surviving blocks

```ruby
doc: [para("ab"), para("cd")]
delete 3..6
actual:   [para("a"), para("d")]
expected: [para("ad")]      # what ProseMirror does
```

Joining is what the open depths drive. Current spec asserts
`result.doc.content.length == 2`.

## Symptom 3: an inline slice across a block boundary produces an invalid document

The slice is spliced at doc level, putting a text node next to paragraphs. Text may
only live inside a block, so this is not a valid ProseMirror document:

```ruby
doc: [para("ab"), para("cd")]
replace 3..6 with inline "XY"
actual: [para("a"), text("XY"), para("d")]    # invalid
```

Also asserted as a known limitation.

## What the fix needs

Open-depth fitting. When a slice has open boundaries, the surviving edges either
side of the range must be fitted together at the right depth rather than spliced
flat. Then:

- `content_between` cuts the range into a properly-depthed slice instead of
  collecting nodes, which fixes the round-trip.
- A cross-block delete fits the two open edges together, which joins the blocks.
- An inline slice lands inside a block rather than beside one.

`Node#cut` is the natural home for the range cut. 01 fixed it: `cut_content` is
gone and `cut` now delegates to `replace`, tree-local, keeping exactly what
`replace` removes. **This PR gives `cut` its first production caller**, which is
why the `cut` contract must be settled before starting here. See the dissent note
in [06](06-prosemirror-position-parity.md): tree-local was chosen over
content-space, and that choice was contested.

## Specs

Three `KNOWN LIMITATION` specs in `replace_spec.rb` assert today's wrong output
(the round-trip, the unjoined paragraphs, the invalid inline splice). Rewrite all
three to assert correct behaviour. Do not delete them.

## Not in this PR

Making `replace` schema-aware is a separate concern. A plain `Node` carries no
`NodeType`, so `replace` cannot know what a parent may contain and places content
wherever the position resolves. That needs the runtime-to-schema bridge, so it
lives in [04](04-schema-alignment.md). The list case below is the visible symptom
and is asserted as a known limitation today:

```ruby
doc: [bullet_list([item("a"), item("b")])]
insert a paragraph at the item boundary
actual: [bullet_list([item, paragraph, item])]   # schema-invalid
```
