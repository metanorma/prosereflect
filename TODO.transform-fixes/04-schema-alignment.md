# PR 04: Align the schema model and bridge it to runtime

**Size:** medium, and splittable into 4a / 4b. **Depends on:**
[03](03-slice-depths-and-invert.md) for the replace half only.

Grouped because everything here is the same underlying gap: the schema model and
the runtime model are two separate worlds with no connection, and the schema world
is both stale and unused.

This one splits cleanly if it gets too big. 4a is self-contained and can ship
alone.

## 4a: the schema text size model is stale

`lib/prosereflect/schema/node.rb:205`

```ruby
def node_size
  @text.length + 1
end
```

PR #13 changed the runtime `Text#node_size` to `length`, because a text node has no
token of its own. The schema model still carries the old `+1`, so two text-size
models coexist. Copilot flagged this on PR #13 and the observation is correct.

### Why it was left alone

The schema model does not feed the runtime path. Verified:

- Nothing outside `lib/prosereflect/schema/` references `Schema::TextNode` sizes or
  positions.
- Nothing compares a runtime `node_size` against a schema `node_size`.
- `Parser` and `Transform` never touch the schema size model.

The two models never meet, so the mismatch cannot skew the runtime coordinates
PR #13 fixed.

### Why it is not a one-line change

The `+1` is used **consistently within the schema model**. Its own position math
builds on it:

- `Schema::Node#node_size` (`schema/node.rb:25`) sums children
- `Schema::Node#cut` (`:70`)
- `Schema::Node#nodes_between` (`:102`)
- `Schema::Node#descendants` (`:123`)
- `Schema::Fragment#size` (`schema/fragment.rb:15`)
- `Schema::Fragment` position walks (`:79`, `:124`)

Flipping `node_size` alone would leave those inconsistent, which is exactly the bug
class PR #13 fixed on the runtime side.

### The catch: there is no coverage

There are **no schema position specs**. Nothing asserts schema `node_size`, `cut`,
or `nodes_between`, so there is no safety net and no failing-test signal to drive
the change.

### Approach

Mirror PR #13:

1. Write characterization specs for the schema position model as it exists.
2. Flip `node_size` to `@text.length`.
3. Fix the helpers the new specs show to be wrong.
4. Renumber the characterization specs to the corrected values.

## 4b: nothing bridges runtime to schema

Two deferred features are both blocked on the same missing bridge, which is why
they belong together.

### Schema-aware replace

A plain `Node` carries no `NodeType`, so `replace` cannot know what a parent may
contain and places content wherever the position resolves. The inward/outward
tie-break is right for `Document`, where blocks are valid siblings, but it cannot
know it is wrong inside a list:

```ruby
doc: [bullet_list([item("a"), item("b")])]
insert a paragraph at the item boundary
actual: [bullet_list([item, paragraph, item])]   # schema-invalid
```

Asserted as a known limitation in `replace_spec.rb`. Depends on
[03](03-slice-depths-and-invert.md), since correct placement also needs open-depth
fitting.

### Cross-type mark exclusion and rank ordering

Deferred from [02](02-mark-and-attr-steps.md). The exclusion engine already exists
and is tested in `schema/mark.rb` / `schema/mark_type.rb`. What is missing is the
runtime-to-schema bridge plus a built-in default schema. The runtime `Mark::Base`
carries only type and attrs, with no exclusion or rank.

No existing runtime mark defines an exclusion (all eight self-exclude only), so
this changes no present-day behaviour. It is parity work, not a bug fix.

## Suggested split

Ship 4a alone first. It is self-contained, has a clear recipe, and closes the
"two coordinate models" objection that reviewers will keep raising on sight. Then
decide whether 4b is worth it, since it is parity work rather than a fix.
