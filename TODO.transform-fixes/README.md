# TODO: transform and position model

Remaining work in the transform/position layer, grouped into PR-sized pieces.
Found while fixing `ReplaceStep` (PR #12) and the text `node_size` model (PR #13).
Every defect below was verified against the code, not inferred. Line numbers are
accurate as of the `fix/text-node-size-length` branch and will drift; each file
quotes the relevant code so it stays findable.

None of this is a regression from those two PRs. It is pre-existing breakage that
was deliberately left alone to keep each PR focused, plus follow-up the PRs made
possible.

## The PRs

| # | PR | Size | Depends on |
|---|----|------|-----------|
| ~~01~~ | ~~Fix `nodes_between` and `cut_content`~~ | — | **Done** |
| [02](02-mark-and-attr-steps.md) | Make mark and attr steps work | Large | nothing |
| [03](03-slice-depths-and-invert.md) | Slice open depths, invert round-trip, block joining | Large | **the 06 decision** |
| [04](04-schema-alignment.md) | Align the schema model and bridge it to runtime | Medium, splittable | 03 for the replace half |
| [05](05-spec-position-helpers.md) | Replace hardcoded spec positions with computed ones | Small | nothing |
| [06](06-prosemirror-position-parity.md) | **Decide** on ProseMirror position parity (`+1` vs `+2`) | A decision, then very large or zero | nothing |
| [07](07-fragment-cut-and-traversal.md) | `Fragment#cut` and the traversal position bugs | Medium | nothing |

**01 is done.** `nodes_between` no longer skips siblings (both copies), and
`Node#cut` is now tree-local and delegates to `replace`, which deleted the
duplicate `cut_content` coordinate math. `Node#cut`'s contract is now documented
on the method: this node's token at 0, children from 1, and `cut` keeps exactly
what `replace` removes. [07](07-fragment-cut-and-traversal.md) records the three
defects found during that work but deliberately left alone.

**Read [06](06-prosemirror-position-parity.md) before starting
[03](03-slice-depths-and-invert.md).** It is a decision, not a fix, and 03's
implementation strategy depends on the answer. Open-depth fitting is ProseMirror's
own algorithm, written against a `+2` coordinate model that this library does not
use. Building it against the current `+1` model means inventing a bespoke variant
that cannot be ported from upstream and gets thrown away if the model later moves.
06 also now settles `Node#cut`'s contract for good: 01 chose tree-local over
content-space, and that choice was contested (see 06's dissent note).

[02](02-mark-and-attr-steps.md) and [03](03-slice-depths-and-invert.md) no longer
depend on anything from 01, so 02 can go any time.

[05](05-spec-position-helpers.md) is hygiene, not a fix. Do it whenever the churn
gets annoying, or fold it into whichever PR touches those specs anyway. It becomes
worth doing up front if [06](06-prosemirror-position-parity.md) lands on "go",
since it would absorb that renumbering automatically.

## How these were grouped

01 to 05 were the eight issues originally found, collapsed into five because
several share the same underlying machinery and splitting them would mean building
the same thing twice. 06 is different in kind: it is an open decision about whether
this library's coordinate system should match ProseMirror's at all, surfaced while
confirming the PR #13 fix. 07 collects three defects found while doing 01, kept out
of it to keep that PR focused.

The merges:

- **Mark steps and `AttrStep`** both need one position-targeted node rebuild. They
  are the same shape of bug: a step that should target a node or range but only
  ever maps the document's top-level children.
- **`invert` and block joining** both need slice open-depth fitting. `invert` has
  to cut a range into a slice with correct depths; joining has to fit those depths
  back together. Same feature.
- **`nodes_between` and `cut_content`** are both core range walk/cut primitives,
  both small, and three other items inherit their bugs.
- **The schema items** all need the same runtime-to-schema bridge, so schema text
  sizing, schema-aware replace, and mark exclusion belong in one area.

## Specs that assert wrong behaviour on purpose

Several specs currently assert today's incorrect output so it cannot change
unnoticed. They are marked `KNOWN LIMITATION` in the spec files. When you fix the
underlying issue, rewrite those specs to assert the correct behaviour. Do not
delete them.

## Two rules worth keeping

1. Never assert only `expect(result).to be_ok`. Assert the produced document. A
   vacuous `be_ok` cannot fail when a coordinate starts pointing at the wrong
   place, and PR #13 found two specs that were silently green over a visibly wrong
   document because of exactly this.
2. If a spec hardcodes a position, say in a comment what the number derives from.
   See [05](05-spec-position-helpers.md).
