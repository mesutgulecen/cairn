# 2 — A window that inverted a verdict

## What happened

A fix went out to reduce how often a connection pool was marked down. To check
it, a counter was read for **five minutes** before and **five minutes** after:

    before   167 / min
    after    223 / min

The fix was written up as having failed, and possibly having made things worse.
A revert was the obvious next step.

Measured over a **55-minute** window with no restarts in it, the same counter
read **74 / min** — a 56% improvement. The five-minute samples had caught two
bursts.

The same session made the mirror-image error on a second metric. A request rate
came in at **4,793/h** against a baseline **median** of 3,685/h, and was reported
as a 26% regression caused by the fix. The baseline's own restart-free hours
spanned **3,010–6,116**. The new reading sat mid-range: unchanged. The metric
that had genuinely moved in the same deploy was obvious precisely because it
landed far outside its own range — a per-call cost that fell from 735K to 112K.

## Why it was invisible

Both readings were real measurements, taken correctly, from the right counter.
Nothing was broken. The error was in what they were compared against: a point
estimate against a point estimate, on a metric whose natural spread was wider
than the effect being measured.

A short window on a bursty system does not measure a slower version of the truth.
It measures a different thing — the current burst — and it does so with complete
confidence.

## What it cost

Nearly a revert of a working fix. The cost was avoided by re-measuring, not by
anyone noticing the reasoning was wrong.

## What stops it now

`plugin/rules/measurement-discipline.md` §1.1: compare against the baseline's
**range**, not its median, and say whether the new reading falls inside it. State
the window, and make it long enough to contain the system's slow phases.

`packs/general/deploy-verify-run.md` builds the same discipline into the routine
post-deploy check, and separates two things that get conflated: an **activation**
counter (did it take effect) and an **outcome** metric (did it help). Both need
the long window; a rising activation counter with a flat outcome means the
diagnosis is incomplete, not that the fix is wrong.
