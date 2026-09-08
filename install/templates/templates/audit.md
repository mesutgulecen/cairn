# <Area> audit, <YYYY-MM-DD>

**Scope:** <what is in, what is deliberately out> · **Mode:** read-only ·
**Previous run:** <path or "first run">

## How to read this

Every finding carries evidence: a query result, a log line, a command output or a
`file:line`. A finding without evidence is labelled `UNVERIFIED` and stays in the
report. Dropping it hides the gap; promoting it invents a fact.

Numbering continues from the previous run. Never renumber: a finding id is how
two documents six months apart refer to the same thing.

## Summary

| Verdict | Count |
|---|---|
| confirmed | |
| refuted | |
| unverified | |
| instrumentation gap | |

One paragraph: what is healthy, what is not, and what you would fix first.

## Measurements

Every number carries its population and window.

| Metric | Value | Population | Window | n |
|---|---|---|---|---|

For anything spiky, quote `mean, [min, max]` rather than a single figure, and say
whether the current reading falls inside the range the baseline already had.
Report per-arm values separately until every arm has reported.

## Findings

### <ID>-<n> · <one-line title> · `confirmed` | `refuted` | `unverified`

- **Evidence:** <the raw thing>
- **Mechanism:** <why it happens>
- **Impact:** <quantified, or "unsized" plus the query that would size it>
- **Recommendation:** <what to change; or "none, accepted risk", with the reason>

## Instrumentation gaps

What could not be measured with what exists today, and the cheapest thing that
would make it measurable. This section is how the next run gets better than this
one.
