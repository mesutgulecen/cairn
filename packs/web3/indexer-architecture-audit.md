# Prompt: indexer as one data plane

The most valuable prompt in this pack, and the least glamorous. An indexer is
usually described in terms of the chains it supports; it should be described in
terms of **unit economics** and **integrity**, because those are what decide
whether it is affordable and whether anything downstream can be trusted.

| Argument | Default | Meaning |
|---|---|---|
| `mode` | `map` on the first run | `map` (architecture only, no production) \| `measure` |
| `window` | 24h | measurement window |
| `output` | `docs/audits/<date>/indexer-<date>.md` + a run ledger | report path |

## The five denominators

Everything else is commentary. Measure each **per chain**, and never aggregate until
every arm has reported, because one arm's number is routinely the inverse of
another's.

| # | Metric | Unit | Why it is the right denominator |
|---|---|---|---|
| P1 | provider cost per 1,000 events | credits/CU per 1K | absolute spend hides a volume change; per-event exposes it |
| P2 | block timestamp → row committed | seconds, p50 **and** p95 | the mean is useless here; the tail is the product |
| P3 | stored bytes per event | bytes | drives retention, backup and query cost together |
| P4 | captured share | % of on-chain events, diffed against the chain | a self-report cannot see what it never saw |
| P5 | read latency at the serving edge | p95 | what a consumer actually experiences |

Publish `accounted` against `total` for anything you decompose. A gap is an
un-instrumented stage, not noise.

## The integrity ladder

Rate each level `met` / `partial` / `unmet`, with evidence:

- **L0. It arrives.** Every source has a live cursor; no cursor is older than
  its own definition of stale.
- **L1. It arrives once.** Idempotency is enforced by a key the database owns,
  not by application logic that assumes it never retries.
- **L2. It is complete.** Gaps are *detected*, recorded and re-fetchable. A
  system that cannot name its gaps has none only in the sense that it cannot see
  them.
- **L3. It is correct.** Sample against the chain, not against yourself.
- **L4. It is timely.** P2 within its stated budget.
- **L5. It is durable.** Retention exceeds the widest consumer's window. Check
  the widest, not the typical: a table-level retention is a **ceiling**, and per
  arm the real content can be far shorter than the setting suggests.

## Traps this audit exists to catch

1. **A generated column presented as observed.** If a timestamp is interpolated
   rather than taken from the source, it is wrong in a way that is invisible:
   two events from the same block can land hours apart, in different partitions,
   with the wrong ordering, while every consumer treats that column as the time
   axis. Establish where each timestamp *comes from* before using it to measure
   anything, including the block rate you use to size capacity.
2. **Cumulative statistics do not describe today.** Database statement statistics
   are cumulative since reset; a mean over months says nothing about the current
   hour. Snapshot, wait, diff.
3. **A cap that is exactly binding looks like headroom.** If several runs process
   *exactly* the maximum, the limit is binding and your throughput number is the
   limit, not the capability.
4. **Cost attributed to the wrong consumer.** Tag calls by consumer at the point
   of dispatch. One system had 82% of its provider spend unattributed; a one-line
   tag reduced that to 3% and named a consumer that appeared on no hypothesis
   list. All three guesses were wrong.
5. **A zero that means "not measured".** If a provider's cost is not priced, its
   recorded cost is zero, which reads as "free" in every aggregate. Group by
   provider before comparing anything.

## Output

Findings, the five denominators as a table, the ladder with evidence, and a run
ledger entry so the next run can diff against this one rather than starting over.
