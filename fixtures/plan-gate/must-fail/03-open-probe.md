# Payment retry rework — plan

**Tier:** K2 · **Owner:** platform

## Assumption Ledger

| # | Assumption | Source | Status |
|---|---|---|---|
| 1 | The processor returns a retryable code on timeout | vendor docs | ✅ confirmed |
| 2 | Fewer than 200 captures/day reach the manual queue | — | [NEEDS PROBE] |

## Internal-state premises

| # | Claim about our own system | Read that would refute it | Status |
|---|---|---|---|
| 1 | The retry flag is deployed | flag audit on the running service | [NEEDS PROBE] |

## Activation Proof

A log line `retry.scheduled attempt=1` within 30 minutes of deploy.

## Pre-Mortem

If backoff is too aggressive we double the load on the processor.
