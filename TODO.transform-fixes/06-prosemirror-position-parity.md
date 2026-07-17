# PR 06: Decide on ProseMirror position parity (element `+1` vs `+2`)

**Size:** very large, or zero. **Type:** a decision first, a PR only if the answer
is "go".

This is not a bug report. It is a fork in the road that will otherwise get decided
by omission. Read it before starting [03](03-slice-depths-and-invert.md), because
03's implementation strategy depends on the answer.

## The gap

`Text#node_size` now equals the character count, which matches ProseMirror. Leaf
nodes are 1, which also matches. **Element nodes do not match.**

| | prosereflect | ProseMirror |
|---|---|---|
| text node | `text.length` | `text.length` |
| other leaf (image, hard_break) | `1` | `1` |
| non-leaf (para, doc) | `1 + content` (open token only) | `content + 2` (open **and close**) |

prosereflect also gives the doc itself an opening token at position 0, where
ProseMirror's doc content starts at 0.

## Verified numbers

prosereflect, measured:

```
doc(p("hi")):        text 2, para 3, doc 4
doc(p("ab"), p("cd")): para 3 each, doc 7
```

ProseMirror, per its documented `nodeSize` (text = character count, leaf = 1,
non-leaf = content + 2):

```
doc(p("hi")):        text 2, para 4, doc.content.size 4
doc(p("ab"), p("cd")): para 4 each, doc.content.size 8
```

The one-paragraph totals agree at 4 by coincidence of that shape. They diverge as
soon as a second block appears: **7 vs 8**.

Position-by-position for `doc(p("hi"))`:

| pos | prosereflect (verified) | ProseMirror (per spec) |
|-----|-------------------------|------------------------|
| 0 | doc level | before paragraph (doc level) |
| 1 | paragraph token | before "h" (inside para) |
| 2 | "h" | between "h" and "i" |
| 3 | "i" | after "i", still inside para |
| 4 | doc level (end) | after paragraph (doc level) |

A position integer means different things in the two libraries. A position taken
from a ProseMirror editor on the web does not address the same spot here.

## What the missing close token already costs

Look at position 3. ProseMirror can express "at the end of the paragraph's text,
still inside the paragraph" (depth 1). prosereflect cannot: it jumps from inside
the text straight to doc level. Those two locations collapse onto one integer.

That collapse is exactly why `replace` carries the `inline_insertion?` heuristic:

```ruby
# This model gives a node no closing token, so a position at child_end is
# both the end of that child's content and the start of its next sibling.
# Inline content has nowhere valid to live out here among block siblings,
# so it resolves inward; block content resolves outward as a sibling.
def inline_insertion?(from, to, nodes)
  from == to && nodes.any? && nodes.all?(&:inline?)
end
```

The code has to **guess** the caller's intent. ProseMirror never guesses, because
the close token separates the two positions. Moving to `+2` would let this
heuristic and its tie-break rules be deleted outright, not rearranged.

## Why this is a real decision, not a nit

`CLAUDE.md` states the library "aims to be a full superset of the Python
prosemirror-py" and points at achieving "complete compliance and schema validation
parity". At the position level that is not true today, and PR #13 did not change
it. PR #13 moved text from wrong to right; the element scheme is still a different
coordinate system.

Either the superset claim is qualified in the docs, or the model moves. Right now
the codebase quietly implies the first while the README implies the second.

## Option A: keep `+1`, document it as a deliberate divergence

- Cost: near zero.
- Consequence: positions are not interchangeable with ProseMirror or
  prosemirror-py. `inline_insertion?` and its guessing stay forever. Every future
  port of a ProseMirror algorithm (fitting, joining, mapping) has to be
  re-derived rather than translated, because they all assume `+2`.
- Required: amend the superset claim in `CLAUDE.md` and the docs to say positions
  intentionally differ, so nobody trusts a PM position here.

## Option B: move to `+2` for real parity

- Cost: very large. This re-does the coordinate model.
  - `Node#node_size` becomes `content + 2`; the doc stops contributing its own
    token at 0.
  - Everything positional needs review: `resolve`, `nodes_between`, `cut`,
    `cut_content`, `replace`, `splice`, `head_of` / `tail_of`,
    `child_to_descend_into`, `StepMap`, `Mapping`.
  - Every hardcoded spec position renumbers again, a bigger sweep than PR #13's
    28 assertions.
- Payoff: positions become interchangeable with ProseMirror and prosemirror-py.
  `inline_insertion?` is deleted rather than maintained. ProseMirror's own
  algorithms become portable instead of needing reinvention.

## Ordering, and why this blocks 03

If Option B is ever going to happen, sequence matters:

1. **Decide this before starting [03](03-slice-depths-and-invert.md).** Open-depth
   fitting is ProseMirror's `replace` / `Fitter` algorithm, and that algorithm is
   written against the `+2` model with open and close tokens. Implementing fitting
   under the `+1` model means inventing a bespoke variant that cannot be ported
   from upstream, then throwing it away if the model later moves. Doing 03 first
   and 06 second is the expensive order.
2. **Do [05](05-spec-position-helpers.md) first if Option B is chosen.** Computed
   spec positions would absorb the renumber churn automatically instead of forcing
   a second mass hand-edit. 05 is cheap and pays for itself here.
3. [04a](04-schema-alignment.md) is unaffected either way and can proceed.

## Recommendation

Decide the direction now, even if the answer is "not yet". If the superset goal is
real, Option B is the only way there, and every PR built on the `+1` model in the
meantime (especially 03) is work that gets redone. If the superset goal is
aspirational, say so in `CLAUDE.md` and stop paying interest on a parity claim the
code does not honour.

## Confidence note

The prosereflect numbers above were measured on the `fix/text-node-size-length`
branch. The ProseMirror figures come from its documented `nodeSize` definition and
were not executed, since there is no JS runtime in this repo. Confirm against
`prosemirror-model` or `prosemirror-py` before committing to Option B.
