# Prompt — regression class sweep

One bug pattern, swept across the whole codebase. Run it when a pattern is
identified — and **always** when the same pattern bites a second time.

| Argument | Default | Meaning |
|---|---|---|
| `pattern` | required | the signature, as a description and as a grep |
| `mode` | `report` | `report` \| `apply` (apply needs explicit authorisation) |
| `output` | `docs/audits/<date>/sweep-<slug>-<date>.md` | report path |

## Method

**1 — Write the signature as a grep, then validate the grep against known
positives.** Take the instances you already know about and check the pattern
finds *all* of them. If it drops one, the criterion is wrong — not the known
positive. This is the step people skip, and it is the step that determines
whether the sweep is worth anything.

A criterion can be inversely correlated with the risk it screens for. One
proposed rule — "files naming two or more identifiers" — excluded two of the
eleven files a human had already flagged, because naming exactly one identifier
*is* the dangerous shape.

**2 — Widen deliberately, and measure the cost.** Compare the strict and loose
forms before choosing: how many more files, how many more real findings. Decide
with both numbers in front of you, not from taste.

**3 — Verify each hit adversarially.** Every candidate is `CONFIRMED`, `REFUTED`
or `UNVERIFIED`. Try to prove each one is *not* a bug: find the caller that never
passes that value, the guard upstream, the test that covers it. A sweep that
reports every grep hit as a finding trains people to ignore sweeps.

**4 — Propose the mechanism that closes the CLASS.** Fixing the instances is the
smaller half. A lint, a type, a shared case table, a test that fails when the
pattern reappears — something that makes the next instance impossible or loud.

**5 — Keep the curated list as a union base.** If the mechanism is derived (a
rule over file contents), keep the hand-made list too and pin with a test that it
is not a subset. Some of the riskiest files match no derivable rule at all, and
deleting the curated list as "redundant" shrinks coverage silently.

## Output

A table of every instance with its verdict, then the class-closing mechanism, then
what you deliberately did not sweep and why.
