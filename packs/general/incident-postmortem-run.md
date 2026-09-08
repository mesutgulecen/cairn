# Prompt: incident post-mortem

Symptom-triggered. **Do not run this without a symptom**: a post-mortem written
from a hunch produces a plausible mechanism and an unverifiable fix, and it burns
the credibility of the ones written from evidence.

| Argument | Default | Meaning |
|---|---|---|
| `symptom` | required | the observation that triggered this |
| `severity` | inferred | `money` \| `data` \| `availability` \| `cosmetic` |
| `output` | `docs/audits/<date>/incident-<slug>-<date>.md` | report path |

Fills `templates/incident.md`. Every mandatory field is evidence-based; an
unknown is written `UNVERIFIED` with the read that would settle it.

## Method

**1. Pin the symptom in data before theorising.** One row, one log line, one
counter. Write down the query that found it; you will need it again to size the
impact and to prove the fix.

**2. Find the first bad event, not the first noticed one.** The gap between them
measures your instrumentation. It is usually the most useful number in the
document, and it is only obtainable now: logs expire in hours, database counters
in months.

**3. Size the blast radius with a count, not a sample.** A sample finds a
candidate; only a count sizes it. If you cannot count it, say `unsized` and give
the query that would.

**4. Get to a mechanism, not a category.** "A race condition" is a category.
*Which* two operations, in what order, on what state, and what makes the window
wide enough to hit.

**5. Answer "why was this invisible?"** What let it pass review, tests and
monitoring. This is the section that produces a durable fix rather than a patch,
so it is the one to spend time on.

**6. For `severity: money`, write the failing test first.** It must fail on the
unfixed code. A test written after the fix asserts your understanding of the fix,
not the behaviour of the bug.

**7. Sweep for the same pattern.** Hand off to the regression-class sweep. Report
what you searched for and what you found, including "searched, found none".

## Stopping rule

After two failed corrections, stop patching. Clear the context and restart from a
different question: *what invariant did this chain violate?* A third patch on a
dirty context is how a two-link fix chain becomes a four-link one.
