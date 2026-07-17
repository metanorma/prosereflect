# TODO 07: `Fragment#cut` and the traversal position bugs

**Size:** medium. **Depends on:** nothing. **Found:** while doing TODO 01.

Four issues found and verified while fixing the position primitives (three
defects plus one unowned design asymmetry), all deliberately left alone to keep
that PR focused. None is a regression from it.

All three are **dead or near-dead code today**, which is why the suite is green
over them. TODO 03 is the first thing that will care.

## 1. `Fragment#cut` is broken

`lib/prosereflect/fragment.rb:39` (`cut`), `:47` (`cut_nodes`), `:64`, `:68`

```ruby
def in_range_before_from?(_pos, node_end, from)
  node_end <= from        # true when the node ends BEFORE the range starts
end
...
result << node if in_range_before_from?(pos, node_end, from)   # ...and it is added
result << node if overlaps_range?(pos, node_end, from, to)
```

It appends nodes that end entirely before the requested range, and it never calls
`node.cut`, so it cannot produce a partial at all. Measured on
`Fragment[text("first"), text("second")]`, size 11:

| call | actual | expected |
|---|---|---|
| `cut(5, 11)` | `["first", "second"]` | `["second"]` |
| `cut(2, 4)` | `["first"]` | a partial, `"rs"` |
| `cut(0, 3)` | `[]` | `"fir"` |

`overlaps_range?` is also wrong: `(pos >= from && node_end <= to) || (pos < from && node_end > from)` catches a node straddling the start but not one straddling the end.

**No caller in `lib`.** `Slice#cut` has its own `cut_internal` (commented
"Simplified cut - just adjusts open flags") and does not route through this.

**Do not copy TODO 01's decision across.** `Node#cut` was made **tree-local**
because a Node has its own token at 0. A Fragment has **no token of its own**, so
its natural space is **content** (its first child starts at 0). They are different
contracts on purpose. `Fragment#size` already sums children with no `+1`.

## 2. `nodes_between` caps a position with a child count, so `descendants` drops nodes

`lib/prosereflect/node.rb:287` (the recursive call)

```ruby
child.nodes_between(
  [0, from - pos - 1].max,
  [child.content ? child.content.size : 0, to - pos - 1].min,   # <- Array#size
  cb, child_start,
)
```

`child.content.size` is Ruby's `Array#size`, the **number of children**, used
here as a **position** bound. For a paragraph holding one text node it is `1`
while its position size is `2`.

This makes `descendants` silently drop nodes:

```ruby
doc(paragraph("ab", "cd")).descendants
# visits: paragraph, "ab"
# misses: "cd"
```

The cap of `2` (the child count) halts the walk after the first child's 2
positions. A node with a single child masks it entirely, which is why casual
checks pass. This is **independent of** the sibling-skip bug fixed in TODO 01 and
is unchanged by it.

The bound should be the child's content position size (the sum of its children's
`node_size`), not the child count. `child.node_size - 1` is that value, and it is
safe here because the recursion only enters non-text children that have content.

### It is a one-line fix that you cannot ship on its own

Measured. Applying just that bound fix:

```
doc(paragraph("ab","cd")).descendants
  before: paragraph, "ab"
  after:  paragraph, "ab", "cd"      # correct
```

but the suite goes red on one spec, and it is the `invert` known limitation:

```
replace_spec.rb "does not round-trip: the inverse re-inserts whole visited nodes"
  before: "HHelloo"
  after:  "HHelloHelloo"
```

**A more correct traversal makes `invert` worse.** `content_between`
([03](03-slice-depths-and-invert.md)) collects *whole visited nodes* from
`nodes_between` instead of cutting the range, so feeding it more nodes makes it
duplicate more. The bound fix is right; its consumer is wrong.

The cap lives inside the shared `nodes_between`, so `descendants`,
`content_between`, and `AttrStep#find_node_at` all move together. There is no way
to fix `descendants` alone without duplicating the walk.

**So do this with or after [03](03-slice-depths-and-invert.md)**, not before.
Shipping it alone means either pinning `"HHelloHelloo"` as the new known-bad value
(a PR that visibly degrades documented behaviour) or dragging 03 in, which is
itself blocked on the [06](06-prosemirror-position-parity.md) decision. This is
why TODO 01 left it alone despite it being in the very method 01 fixed.

## 3. `Fragment` callbacks report the wrong position

`lib/prosereflect/fragment.rb:106` (`text_node_callback`), `:114` (`full_node_callback`)

```ruby
def text_node_callback(node, pos, from, node_start, callback)
  callback.call(node, node_start + (from - pos).clamp(0, node.node_size))
end
```

It reports `node_start + (from - pos)`, the offset of the **query** into the node,
rather than the node's own start. So:

```ruby
Fragment[text("ab"), text("cd")].nodes_between(2, 4)
# reports "cd" at position 0, should be 2
```

`full_node_callback` ignores `pos` for the same reason. Both
`schema/fragment.rb:118` and ProseMirror derive it from `node_start + pos`.

The TODO 01 spec for the sibling-skip fix asserts **visitation only** and
deliberately does not assert the position, with a comment pointing here.

## 4. `nodes_between` takes content inputs but emits tree outputs

Not a bug so much as an unowned asymmetry, but it caused a false argument during
TODO 01 and will bite TODO 03.

- **Inputs** (`from`/`to`) are **content offsets**: `pos` starts at 0 and
  accumulates `node_size`, and `descendants` passes `nodes_between(0, node_size - 1)`,
  where `node_size - 1` is exactly the content sum.
- **Output** (the position handed to the callback) is a **tree position**:
  `child_start = node_start + pos + 1`.

So the same method speaks two coordinate spaces. Anyone reading `child_start`'s
`+1` as evidence of the input space will be wrong. Decide one, or name the two
explicitly.

## Suggested approach

1 and 3 are both in `fragment.rb` and both about the same walk, so do them
together. They are independent of everything else here.

2 is one line, but it is **coupled to [03](03-slice-depths-and-invert.md)** (see
above) and must go with or after it. When you do it, add a spec proving
`descendants` visits every node of a **multi-child** parent: a single-child parent
passes either way and hides the bug.

4 is a decision to record, and should be settled alongside
[06](06-prosemirror-position-parity.md), since it is the same class of question.
