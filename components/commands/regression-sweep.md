---
description: Sweep one bug pattern across the codebase, with adversarial verification
argument-hint: <pattern description>
---

Apply `docs/prompts/general/regression-class-sweep.md` for: $ARGUMENTS

Validate the grep against the instances you already know about before sweeping.
If it misses one of them, the criterion is wrong, not the known positive.
Every hit is CONFIRMED, REFUTED or UNVERIFIED; try to prove each one is not a bug
before reporting it.
