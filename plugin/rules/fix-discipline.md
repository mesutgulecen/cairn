---
description: Fix-of-fix chains — read the prior fix before changing what it established
paths:
  - "**"   # narrow this to your money path / core logic once installed
---

# Fix discipline

In one week, **19 fixes were regressions caused by a previous fix**, in chains
three and four links long. Not one of them was careless work. Each was a correct
local change to a constant, an exemption or a predicate that an earlier fix had
put there for a reason nobody re-read.

That is the shape of the problem: a fix changes behaviour some other fix
deliberately established, and the person making it cannot see the scenario being
protected, because the protection looks like an arbitrary detail.

When your change touches behaviour a previous fix established:

1. **Read the prior fix first.** `git log -p --oneline <paths>` and whatever
   changelog you keep. Know which scenario the earlier fix protects *before* you
   change the constant, exemption or predicate it added.
2. **Ask "who consumes this?"** Grep every worklist, gate and constraint that
   reads the column, sentinel or flag you are changing. This applies to *values*,
   not only to code paths: a column's freshness is part of its contract. One
   eager-population fix starved a worklist that keyed on the column still being
   empty.
3. **Write the failing test first — and a second test pinning the prior fix's
   scenario.** Name them after the incident so a stale invariant is greppable.
4. **List what must NOT change.** In the plan or the commit, name at least three
   "shall continue to" neighbours: the other variant, the parallel path, the
   adjacent trigger. A fix with no stated blast radius has an unbounded one.
5. **Stop after two failed corrections.** Do not stack a third patch onto a dirty
   context. Clear the session and restart with a fresh question: *what invariant
   did this chain violate?* A clean session with a better prompt beats a long one
   carrying accumulated corrections.
6. **Sweep for the same pattern elsewhere.** A pattern found in one incident is
   rarely alone. One empty-chunk bug bit twice, four days apart, in two callers
   of the same helper.

Structural changes (rename, extract, move) and behavioural changes go in
separate commits, so review can read the behaviour diff on its own.
