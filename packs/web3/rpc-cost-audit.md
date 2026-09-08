# Prompt — RPC cost audit (delta run)

| Argument | Default | Meaning |
|---|---|---|
| `window` | 7d | comparison window |
| `previous` | last run | the run to diff against |
| `output` | `docs/audits/<date>/rpc-cost-<date>.md` + run ledger | report path |

## Method

**1 — Attribute before you optimise.** Group spend by `(provider, key, method,
consumer, hour)`. If a large share is unattributed, stop and fix the tagging
first: optimising an unattributed majority is guessing with extra steps. Tagging
at the dispatch point turned 82% unattributed into 3% in one system, and the
consumer it revealed was on nobody's list.

**2 — Group by provider before comparing anything.** Different providers meter
differently, and an unpriced provider records **zero**, which is indistinguishable
from free in an aggregate. State explicitly which providers are measured and
which are merely counted.

**3 — Separate the two limits.** A key is usually bound by *both* a rate limit
and a periodic quota, and they fail differently: the rate limit produces errors
and backoff, the quota produces a key that answers normally until it dies for the
rest of the period. Read the daily curve — a key that runs flat and then drops to
near-zero for the remainder of the month hit a quota, whatever the error counters
say.

**4 — Cost per unit of work, not cost per day.** Divide by events, requests or
positions, so a volume change does not read as a regression.

**5 — Verify a fix on a clean window.** Compare against the baseline's `[min,
max]`, not its median, and use a window with no restarts in it. A reading that
sits mid-range is unchanged, however different it looks from a point estimate.

**6 — Check what the counter actually counts.** A "usage" counter that only
increments on success reports a system in a retry storm as cheap. A counter that
measures drops does not measure loss.

## Output

A per-consumer table with deltas, the two limits per key, what changed since the
previous run, and a ledger entry. Recommendations are ranked by measured share,
never by how easy they are.
