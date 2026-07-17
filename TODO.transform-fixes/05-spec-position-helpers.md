# PR 05: Replace hardcoded spec positions with computed ones

**Size:** small. **Depends on:** nothing. **Priority:** low.

Not a defect. A maintenance trap, plus the reason a whole class of spec bug went
unnoticed. Do it whenever the churn gets annoying, or fold it into whichever PR is
already touching these specs.

## The problem

Position-dependent specs assert magic integers:

```ruby
expect(node.node_size).to eq(7)
expect(described_class.can_join?(doc, 8)).to be true
r = doc.resolve(5)
ReplaceStep.new(6, 6, slice)
expect(step_map.ranges).to eq([[2, 2, 2, 5]])
expect(slice.size).to eq(6)
```

None of them say *why* the number is what it is, so any change to the coordinate
model forces a hand-edit of every one. PR #13 renumbered 28 assertions across 5
files for a 3-line change.

## The worse half: vacuous specs hide the errors

Several specs asserted only `expect(result).to be_ok` next to a hardcoded
coordinate. A vacuous `be_ok` cannot fail when the coordinate starts pointing
somewhere else, so the suite stays green while the spec tests nothing.

The test run cannot point at these, by definition. PR #13 only found them by
hand-checking every `be_ok`-only spec, and two were real. The heading-delete spec
kept passing while producing a visibly wrong document:

```ruby
# with the stale (8, 15):
[para("first"), heading(""), para("ast")]     # empty heading, "last" trimmed
# with the corrected (7, 13):
[para("first"), para("last")]
```

The blockquote-delete spec had drifted the same way, leaving a stray `"q"`. All
nine `be_ok`-only specs in `replace_spec.rb` were strengthened in PR #13.

## Suggested fix

Compute positions from the model instead of writing literals:

```ruby
end_of(node)        # start + node.node_size
pos_after(node)     # the next sibling's position
start_of(child)     # child_start within its parent
```

A spec then reads `ReplaceStep.new(end_of(para1), end_of(para1), slice)`, which
keeps working across coordinate changes and documents its own intent.

Migrating every spec is probably not worth it. The high-value targets are the ones
that encode a *boundary* (`can_join?`, the paragraph-boundary inserts, the
cross-block ranges), since those are what break on a model change.

## Rules to keep regardless

1. Never assert only `be_ok`. Assert the produced document.
2. If a spec hardcodes a position, say in a comment what the number derives from.
