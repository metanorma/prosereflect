# PR 01: Fix the position primitives

**Size:** small. **Depends on:** nothing. **Blocks:** 02, 03.

Two core range primitives are wrong. Both are contained bugs with clear repros,
and several other defects inherit them, so this goes first.

## 1. `nodes_between` skips siblings

Two copies of the same bug: `lib/prosereflect/node.rb:281` and
`lib/prosereflect/fragment.rb:88`.

Both loops `next` past a non-overlapping child **before** advancing `pos`, so
`pos` goes stale and every later sibling is measured from the wrong offset.

```ruby
# Node#nodes_between
pos = 0
content.each_with_index do |child, i|
  break if pos >= to

  child_end = pos + child.node_size
  next unless child_end > from        # :281  skips without advancing pos

  child_start = node_start + pos + 1
  ...
  pos = child_end                     # :293  never reached for skipped children
end
```

`Fragment#nodes_between` is identical in shape: `next unless node_end > from` at
`:88`, `pos = node_end` at `:91`.

Repro, two paragraphs `"ab"` and `"cd"`, asking for a range inside the second:

```ruby
doc.nodes_between(4, 7) { |node, pos| ... }   # yields nothing
```

The second paragraph should be visited. The first took the `next` branch, so `pos`
stayed 0, the second paragraph's `child_end` never cleared `from`, and the loop
yielded nothing at all.

Fix, in both files:

```ruby
child_end = pos + child.node_size
if child_end <= from
  pos = child_end
  next
end
```

They are separate implementations of the same walk, so both need the change and
both need coverage.

## 2. `cut_content` mis-anchors text children

`lib/prosereflect/node.rb:446` (in `cut_content`).

It does not consistently anchor a text child on its `child_start`, so cutting a
sub-range returns more characters than asked for. A parent whose text child is
`"abcd"`, cut at `2...4`:

```
expected: "bc"
actual:   "bcd"
```

The offset used to cut into the child comes from the wrong base, so the end of the
range is never trimmed.

## Why replace is unaffected by either

`Node#replace` does not use `nodes_between`. It walks via `child_to_descend_into`
/ `each_child_span`, and trims straddling children through `head_of` / `tail_of`,
which call `Text#cut` directly:

```ruby
def head_of(child, from, child_start)
  offset = from - child_start
  return child.cut(0, offset) if child.text?
  child.replace(offset, child.node_size, [])
end
```

`Text#cut` is correct (`cut(1, 3)` on `"abcd"` gives `"bc"`). That is why PR #12
and PR #13 are green despite both of these bugs, and why they were left alone.

## Watch out: `Node#cut` is content-relative

`Node#cut` takes **content-relative** offsets, not tree positions. It sums child
`node_size` with no parent token:

```ruby
node = Node.create("parent")
node.add_child(Text.create("first"))    # node_size 5
node.add_child(Text.create("second"))
node.cut(0, 5)   # => ["first"]        correct
node.cut(0, 6)   # => ["first", "s"]   off by one into the next child
```

A spec in `node_spec.rb` had `cut(0, 1 + 7)` with a comment claiming
`1 parent + first text`, wrong on both counts. PR #13 corrected it to `cut(0, 5)`.
Keep this in mind when fixing `cut_content`.

## Specs to add

- Per file: a range inside a later sibling still visits that sibling.
- Cutting `"abcd"` at `2...4` inside a parent returns `"bc"`.

Neither bug has any coverage today.
