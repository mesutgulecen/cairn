# Capture pipeline speedup — plan

**Tier:** K2 · **Owner:** platform

## Assumption Ledger

| # | Assumption | Source | Status |
|---|---|---|---|
| 1 | The processor tolerates 4 concurrent captures | vendor docs | ✅ confirmed |
| 2 | Retry codes are stable across API versions | was [NEEDS PROBE], answered by the vendor changelog | ✅ resolved |
| 3 | ~~Batch size can exceed 500~~ | [NEEDS PROBE] | ~~withdrawn: the endpoint caps at 500~~ |

## Internal-state premises

| # | Claim about our own system | Read that would refute it | Status |
|---|---|---|---|
| 1 | The worker is single-threaded today | `grep` on the worker's start-up log | ✅ confirmed |
| 2 | The concurrency setting is absent from the deployed config | config dump on the running service | ✅ confirmed |

## Approach

Parallelising the fetch stage gives a 1.26x end-to-end improvement.

**Measured-basis:** per-stage timers around fetch alone, 412 ticks, p50 fetch
1.9s of a 7.4s tick (25.7%, range 21-29%). Not derived by subtracting
processing from total: an intercept absorbs everything that does not scale, and
a fit cannot separate two components that grow with the same N.

The offending block cursor in the reproduction was 0x2fadcb1 and the topic was
0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef.

## Activation Proof

`fetch.concurrency=4` in the worker's start-up line, plus the per-stage timer
histogram reporting a non-zero p50 for the parallel path within 30 minutes.

## Pre-Mortem

Too much concurrency and the processor rate-limits us; the counter above is
also the rollback trigger.
