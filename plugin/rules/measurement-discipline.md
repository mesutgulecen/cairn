---
description: How a number earns the right to drive a decision — population, window, arm, attribution
paths:
  - "**"   # applies to any work that reports or acts on a measurement
---

# Measurement discipline

Every rule below is a mistake that was made while investigating a real system,
and each one looked like a finding at the time. Check a number against these
before you report it, or size a piece of work with it.

## 1. A number without its population and window is not a number

A drain rate was reported as **1.49x the arrival rate** from a **25-minute**
sample. Measured over **9.32 hours** it was **1.043x** — barely above break-even.
A short window on a saturated system measures the current burst, not the
sustainable rate, and it overstates headroom (here by 43%).

Always carry *what population, over what window, n = ?*. If the system's duty
cycle is near 100%, the window must be long enough to contain its slow phases.

### 1.1 Compare against the baseline's RANGE, not its median

A spiky metric compared to a median manufactures a change. A post-fix reading of
**4,793/h** against a baseline *median* of **3,685/h** was reported as "+26%, the
fix made it worse". The baseline's own restart-free hours spanned
**3,010–6,116** — the new value sat mid-range, i.e. unchanged. Quote
`mean, [min, max]` and say whether the reading falls inside it. The metric that
genuinely moved in that same investigation was obvious precisely because it
landed far outside its own range.

A short window can also **invert a fix's verdict**. A counter read 167/min before
a fix and 223/min after, each measured over **five minutes**, and the fix was
written up as ineffective or harmful. Over a **55-minute** window it was
**74/min** — a 56% improvement. Reverting on the short reading would have deleted
a working fix.

So: an *activation* counter and an *outcome* metric are two separate
measurements, and both need the long window. A rising activation counter with a
flat outcome means the diagnosis is incomplete — but confirm the outcome really
is flat over a long enough window before concluding even that.

## 2. One arm's number is not the system's answer

A dedup ratio came back at **1.00** on the first arm and was written down as the
result. That arm runs one batch per cycle, so per-call dedup already *is* cycle
dedup there. The second arm runs 28 batches, and its ratio was **5.94**. The
conclusion — "cycle-scoped dedup buys nothing" — was exactly backwards for the
arm that mattered.

When a metric exists per chain, per tenant, per region, per mode or per plan, no
arm may be generalised until every arm has reported. If one is still missing, say
"arm A: 1.00, arm B pending". Never "the ratio is 1.00".

### 2.1 The arms may live in different tables

Asked whether any account restricted a certain source, one table was queried,
came back empty for all 13 rows, and the answer given was "no restriction". A
second kind of account stores that same setting in a **different table**, and two
of them had explicit lists.

The cheapest guard is general: **name the column in the sentence.** "13 rows have
an empty `accounts.sources`" invites the next question; "13 accounts have no
restriction" closes it. Laundering a column into a behaviour hides the gap from
the writer as much as from the reader.

## 3. A mean can describe none of the calls that matter

A query's cumulative statistics reported a **252 ms mean** over 3.6M calls, and
hours of reasoning followed from it. Timed directly against the real case it was
**16.9 s**, then **27.0 s**. The mean was millions of cheap rows averaging the
expensive tail out of sight.

A cumulative mean over a heavy-tailed population summarises the population, not
the work you care about. For a decision use p50 **and** p95, or time the real
case directly.

## 4. A fit tells you HOW MUCH, never WHERE

"Fetching is 26% of the tick" came from `duration ≈ 15.6s + 60ms × n`, with the
intercept attributed to fetching. Measured with a per-stage timer, fetch was
**0.7%**. An entire phase of work had been sized on that 26%.

Two components that scale with the same n are indistinguishable to a fit, and the
intercept absorbs everything that does not scale. **Never derive a component's
cost by subtraction** — `fetch = duration − processing` would have said ~7%, an
overstatement of ten times. Give the component its own timer, and publish
`accounted_ms` next to `total_ms` so the attribution audits itself.

### 4.1 The dominant consumer is often not on your candidate list

An investigation asked which of five tiers spent the caller's time budget. Both
hypotheses named a tier. The answer was **the rate limiter that runs before tier
one and is not a tier at all: 97.7–98.8%**. Tier one was under 2%; tiers three to
five measured exactly 0 ms. A tier-only trace would have concluded that nobody
consumed the budget.

Enumerate **every stage the call passes through**, not only the ones your
hypothesis names: admission control, rate limiters, connection acquisition, lock
waits, retry sleeps. Then publish `accounted` against `total` and treat a gap as
an un-instrumented stage rather than as noise.

### 4.2 The instrument can reproduce the bug it exists to prevent

That trace's first draft deferred its "stage done" call inside the tier-one
block. Deferred calls are **function-scoped, not block-scoped**, so tier one
absorbed tiers two through five and would have been named the culprit — the exact
mis-attribution this section is about, produced by the tool built to avoid it.

Before trusting a new timer, **verify its scope against a case with a known
answer**: one slow stage, one fast one, and the fast one must stay fast.

## 5. Before changing a shared value's freshness, grep its consumers

Coalescing a recompute was recommended twice before anyone asked who reads the
result. Two of its columns fed a price fallback and a gate's fallback — and the
gate's use was a fallback *for when the primary lags*, which on one arm was the
common path, not the rare one. A column's freshness is part of its contract.

## 6. Run a new guard against something you know should fail

Two guards written in a single session were vacuous on first draft. One
false-positived on a resolved cell; the other grepped for a phrase and passed the
very document that only *described* the section it demanded. Both were found by
running them against a document with a known verdict — not by reading them.

A gate that cries wolf gets switched off; a gate that always passes is worse than
none. Calibrate on one input that must fail and one that must pass.

## 7. Capture `$?` immediately, into a variable

    cmd; rc=$?          # nothing in between
    echo "$name → $rc"

`cmd >/dev/null; echo "$(basename "$f") → exit=$?"` reports **basename's** status:
the command substitution runs first and resets `$?`. It printed `exit=0` for a
document a gate was correctly rejecting with `exit=2` — a verification harness
certifying the opposite of the truth.

**A pipeline resets it too.** `linter 2>&1 | tail -5; echo "rc=$?"` prints
**tail's** status; it nearly went into a report as "all gates green" while the
linter was failing to start. Redirect to a file and check the real status, or set
`pipefail` — and note that `pipefail` has its own trap: a `grep -q` that exits
early kills its upstream with SIGPIPE, and 141 then becomes the pipeline's status.

## 8. Validate a selection criterion against known members of its target class

A lint needed a rule for "which files can leak an identifier". The proposed rule —
files naming **two or more** distinct identifiers — was plausible and wrong in the
direction that matters: measured against the eleven files a human had already
flagged, it **excluded two of them**, because a file that names exactly one
identifier is the leak *shape*, not the safe case. The criterion was inversely
correlated with the risk it screened for.

1. **Run the criterion against your known positives before adopting it.** If it
   drops one, the criterion is wrong — not the known positive. Loosening it here
   cost 21 more files and found 4 more real defects, a trade only visible because
   both options were measured before either was written into the script.
2. **A derivation rarely subsumes the curation it replaces.** Keep the hand-made
   list as a union base and pin, with a test, that it is not a subset: two of the
   riskiest files named no identifier at all, so no identifier-based rule could
   ever reach them. Deleting the curated list as "redundant" would have shrunk
   coverage silently.
