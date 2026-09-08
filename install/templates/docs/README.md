# docs/

Four kinds of document, kept apart because they age differently.

| Directory | Holds | Ages |
|---|---|---|
| `decisions/` | how a subsystem works and why it was built that way | slowly — update in place |
| `plans/<date>/` | what you intended to do, and the evidence you had | never — dated, never edited after the fact |
| `audits/<date>/` | what you measured, with its population and window | never — dated, numbering continues across runs |
| `runbooks/` | how to perform an operation safely | on every topology change |

Two rules that keep this from rotting:

1. **Dated output is never overwritten.** A plan that turned out to be wrong is
   more valuable than one quietly corrected: the next reader learns which kind of
   reasoning failed. Write a new dated document and link back.
2. **A finding id is permanent.** Numbering continues from the last run, so two
   documents six months apart can refer to the same thing. Never renumber.

Keep a `plans/<date>/<phase>-progress.md` current while a phase is active — done
(with commit and one line of evidence), next (and why), blocked (and by what).
The session-start hook surfaces it, which is what turns a cold start into a
resumption.
