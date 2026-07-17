# PR 02: Make mark and attr steps work

**Size:** large. **Depends on:** nothing (01 is done).

Grouped because these are the same bug wearing different hats. Every one of these
steps should target a node or a range, and every one of them instead maps only the
document's top-level children. They all need one shared primitive: a
position-targeted descent that rebuilds the node it lands on. Building that twice
would be waste.

`ReplaceStep` already got this treatment in PR #12. These are the steps left
behind.

## Part A: all four mark steps

`lib/prosereflect/transform/mark_step.rb`. There is no `mark_step_spec.rb`, which
is how all of this survived.

### `AddMarkStep#apply` is a silent no-op

```ruby
def add_mark_to_range(doc)                                   # :69
  new_content = doc.content.map { |node| apply_mark_to_node(node) }
  doc.copy(new_content, doc.attrs.dup)
end

def apply_mark_to_node(node)                                 # :74
  return node unless node.is_a?(Prosereflect::Text)
```

It maps only `doc.content`, the top-level children. Those are block nodes, never
`Text`, so every one returns unchanged. `@from` and `@to` are never read. The step
reports `Result.ok` and changes nothing.

### `RemoveMarkStep#apply` always fails

```ruby
class AddMarkStep < MarkStep
  private                                                    # :67
  def remove_mark_from_range(doc)                            # :84
end

class RemoveMarkStep < MarkStep                              # :102
  def apply(doc)
    new_doc = remove_mark_from_range(doc)                    # :107
  rescue StandardError => e
    Result.fail(e.message)
```

`remove_mark_from_range` is a private method of `AddMarkStep`, unreachable from the
sibling class. It raises `NoMethodError`, which the `rescue StandardError`
swallows into `Result.fail`. The step never removes a mark and never raises. It
quietly returns a failed result carrying a `NoMethodError` message.

### Wrong accessor

Lines 79, 92, 198, 260 use `node.marks`, which returns hashified marks, then call
`.type` on them or pass them to `Text.new(marks:)`. The accessor returning real
`Mark::Base` objects is `node.raw_marks`.

### Node mark steps only reach the top level

`AddNodeMarkStep` / `RemoveNodeMarkStep` map only `doc.content`, so they cannot
target a nested node.

### `Mark.from_h` does not exist

Called in all four `from_json` methods (lines 63, 140, 186, 248):

```ruby
mark = Prosereflect::Mark.from_h(json["mark"])
```

It is not defined anywhere in `lib/`. Mark step deserialization raises
`NoMethodError`.

## Part B: `AttrStep`

`lib/prosereflect/transform/attr_step.rb`.

### Crashes when the target has no attrs

```ruby
def compute_new_attrs(target_node)          # :64
  new_attrs = target_node.attrs.merge(@attrs)
```

`attrs` is `nil` on plenty of nodes (a plain `Paragraph` parsed from JSON has
`@attrs=nil`), so `nil.merge` raises. `apply`'s `rescue StandardError` turns it
into a confusing `Result.fail`.

### Only replaces top-level nodes

```ruby
def replace_node_with_new_attrs(doc, target_node, new_attrs)   # :70
  new_content = doc.content.to_a.map { |node| replace_node(node, target_node, new_attrs) }
```

`find_node_at` searches the whole tree, so it can return a nested node. But this
only maps `doc.content`. If the target is nested, nothing matches, the document
comes back unchanged, and the step reports success.

### Inherits the traversal bug

```ruby
def find_node_at(doc, pos)      # :85
  doc.nodes_between(pos, pos + 1) { |node| result = node }
```

`nodes_between` used to skip siblings, so this could return the wrong node or
nothing. Fixed in 01, so `find_node_at` gets that for free. Its other two bugs
(nil attrs, top-level-only replacement) remain.

## What the fix needs

A design doc for the mark half already exists and was reviewed:
`docs/plans/2026-07-16-mark-steps-parity-design.md` (local, uncommitted).

- `Node#update_marks(from, to, &transform)`: a recursive walk mirroring the
  `Node#replace` walk, splitting text at range boundaries via `Text#cut` and
  reusing `merge_adjacent_text`.
- `add_to_set` / `remove_from_set` / `is_in_set?` on `Mark::Base`.
- **A position-targeted node rebuild, shared by the node-mark steps and
  `AttrStep`.** This is the reason the two halves are one PR.
- Add `Prosereflect::Mark.from_h`.
- Default `attrs` to `{}` at the boundary rather than guarding every call site.
- Stop letting `rescue StandardError` hide programming errors. Validate positions
  and let genuine bugs surface.
- A new `mark_step_spec.rb` with real coverage, and real coverage for `AttrStep`.

This depends on text `node_size = length` (PR #13), because a mark step must not
move content, and under the old `length + 1` model splitting a text node to mark a
sub-range changed the document size.

## Out of scope here

Cross-type mark exclusion and rank ordering need the runtime-to-schema bridge. See
[04](04-schema-alignment.md). No existing runtime mark defines an exclusion, so
deferring it changes no present behaviour.
