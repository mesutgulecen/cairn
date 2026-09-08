# Payment retry rework — plan

**Tier:** K2 · **Owner:** platform

## Assumption Ledger

| # | Assumption | Source | Status |
|---|---|---|---|
| 1 | The processor returns a retryable code on timeout | vendor docs | ✅ confirmed |

This plan also discusses internal-state premises at length: we believe the
retry flag is already deployed and that the backfill completed last month.
Those are internal-state premises and the reader should treat them as such.

## Activation Proof

A log line `retry.scheduled attempt=1` within 30 minutes of deploy.

## Pre-Mortem

If backoff is too aggressive we double the load on the processor.
