---
name: audit-authoring
description: Write an audit or investigation report whose numbers can be trusted — population and window on every metric, per-arm before aggregate, evidence or an explicit UNVERIFIED label. Use when reporting measurements, writing an audit, or answering "how is X doing" with numbers.
---

# Authoring an audit

The failure mode of an audit is not being wrong. It is being *plausible* — a
number without its population, a mean that describes none of the cases that
matter, a conclusion drawn from one arm of a system that has several.

## Every number carries four things

**Value, population, window, n.** A rate measured over 25 minutes on a saturated
system is the current burst, not the sustainable rate: one such reading said
1.49x where nine hours said 1.043x, overstating headroom by 43%.

For anything spiky, quote `mean, [min, max]` and say whether the new reading
falls **inside** the range the baseline already had. A value compared to a median
manufactures changes: 4,793 against a median of 3,685 reads as +26% until you
notice the baseline itself spanned 3,010–6,116.

## Report per arm before you report a system

When a metric exists per chain, tenant, region, currency or kind, no arm may be
generalised until every arm has reported. One ratio came back at 1.00 on the arm
that runs a single batch and 5.94 on the arm that runs 28 — the conclusion drawn
from the first was exactly backwards for the one that mattered.

And **name the column in the sentence**. "13 rows have an empty
`accounts.sources`" invites the next question; "13 accounts have no restriction"
closes it — and hid the second table where the other kind stores that setting.

## Use p50 and p95, never a bare mean

A cumulative mean over a heavy-tailed population summarises the population, not
the expensive work. One query's 252 ms mean over 3.6M calls was 16.9 s when timed
against the case anyone cared about.

## Attribute by timing, never by subtraction

`component = total − everything else` overstates whatever is left. Give each
stage its own timer and publish `accounted` against `total`; a gap is an
un-instrumented stage, not noise. Enumerate every stage the work passes through,
not only the ones your hypothesis names — the dominant consumer is regularly one
nobody listed.

Before trusting a new timer, calibrate it against a case with a known answer.

## Label what you could not verify

`UNVERIFIED` with the read that would settle it, or `INSTRUMENTATION GAP` with
the cheapest thing that would make it measurable. Both stay in the report.
Dropping them hides the gap; promoting them invents a fact.

## Keep the numbering

Findings continue from the previous run and are never renumbered. A finding id is
how two documents six months apart refer to the same thing.

Template: `templates/audit.md`.
