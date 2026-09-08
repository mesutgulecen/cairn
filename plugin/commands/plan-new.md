---
description: Start a plan from the template, at the right tier
argument-hint: <slug> [tier]
---

Create `docs/plans/$(date +%F)/$1-$(date +%F).md` from `templates/plan.md`.

Pick the tier honestly: K0 for a one-sentence change, K1 for a bug fix with a
known cause, K2 for the money path, a new integration or instance, or a flag that
changes production behaviour. Only K2 is gated — **lower the tier rather than
filling in ceremony**, and delete the sections that do not apply. An empty
section is worse than an absent one: it reads as considered and dismissed.

Fill the Assumption Ledger and the Internal-state premises first, before the
approach. Mark anything unresolved `[NEEDS PROBE]` and resolve it before writing
code — most cancelled work starts as a premise nobody read.
