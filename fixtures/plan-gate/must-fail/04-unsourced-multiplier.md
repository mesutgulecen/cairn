# Capture pipeline speedup — plan

**Tier:** K2 · **Owner:** platform

## Assumption Ledger

| # | Assumption | Source | Status |
|---|---|---|---|
| 1 | The processor tolerates 4 concurrent captures | vendor docs | ✅ confirmed |

## Internal-state premises

| # | Claim about our own system | Read that would refute it | Status |
|---|---|---|---|
| 1 | The worker runs single-threaded today | ✅ confirmed by the run log | ✅ |

## Approach

Parallelising the fetch stage should give us a 1.26x end-to-end speedup, since
fetch is roughly a quarter of the tick according to how tick duration grows
with batch size.

## Activation Proof

Concurrency counter above 1 in the worker's own metrics.

## Pre-Mortem

Too much concurrency and the processor rate-limits us.
