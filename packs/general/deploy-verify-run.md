# Prompt — post-deploy verification

Run at **T+30min** after a deploy or a flag flip. Its purpose is narrow and
unglamorous: prove the thing you shipped is *running* and *taking effect*, before
anyone reasons from the assumption that it is.

| Argument | Default | Meaning |
|---|---|---|
| `change` | last deploy | what shipped: commit, flag, migration |
| `mode` | `t30m` | `t30m` \| `t48h` \| `t7d` re-verification |
| `output` | `docs/audits/<date>/deploy-verify-<date>.md` | report path |

## The three questions, in order

**1 — Is the new code actually running?** Compare the build identifier reported
by the running service against the commit you intended to ship. "The pipeline was
green" is not an answer: a green pipeline that skipped the deploy step is the
common failure, not the exotic one.

**2 — Does the environment carry the configuration?** Every new key the change
introduced must exist in the deployed environment with the intended value. A
feature whose flag was never added lands dormant, looks identical to a bug, and
is usually found months later by accident.

**3 — Activation proof.** State the single observation that could only be true if
the change took effect — a log line, a counter, a query result — and go and look
for it. Rules of evidence:

- **A populated column is not activation proof.** It may have been populated by
  the old path, a backfill or a default.
- **A log line saying "enabled" is not proof either** unless the executing branch
  is what emits it. Guards get logged as armed and then never consulted.
- **An activation counter and an outcome metric are two measurements.** Both
  need a window long enough to include the system's slow phases.

## Then, the metric

For the specific metric the change was meant to move: report `p50` **and** the
range, before and after, over comparable windows. If the baseline was spiky,
compare against its `[min, max]` and say whether the new reading falls inside it
— a single value sitting mid-range is *unchanged*, not improved.

A five-minute window can invert a verdict. One fix read as ineffective over five
minutes and as a 56% improvement over fifty-five.

## Verdict

One of: `confirmed` · `no effect` · `regressed` · `cannot measure yet` (with what
would make it measurable and when to look again). Record the re-verification date
for `t48h` / `t7d`.
