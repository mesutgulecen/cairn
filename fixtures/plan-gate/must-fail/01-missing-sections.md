# Payment retry rework — plan

**Tier:** K2 · **Owner:** platform

## Approach

Retry failed captures with exponential backoff, capped at four attempts, then
route to the manual queue.

## Steps

1. Add the backoff schedule.
2. Wire the manual queue.
3. Ship behind a flag.
