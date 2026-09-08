# <Title> — plan (<YYYY-MM-DD>)

**Tier:** K2 · **Owner:** <name> · **Status:** draft

> **Tiers.** K0 = a one-sentence change. K1 = a bug fix with a known cause.
> K2 = anything on the money path, a new integration or instance, or a flag that
> changes production behaviour. Only K2 is gated; if this is not one, lower the
> tier rather than filling in ceremony. Deleting a section you did not need is
> honest. Leaving it empty is not.

## Problem

What is wrong, for whom, and how you know. One paragraph. If you cannot state the
symptom, you are not ready to plan.

## Assumption Ledger

Premises about things **outside** your control. Anything unresolved is marked
`[NEEDS PROBE]`, and implementation does not start while one is open — the gate
enforces this, but the rule is yours, not the gate's.

| # | Assumption | How it was checked | Status |
|---|---|---|---|
| 1 | <the provider returns X on timeout> | vendor docs + one live call | ✅ confirmed |
| 2 | <rate limit is N/min per key> | was [NEEDS PROBE]; measured 118/min over 40 min | ✅ resolved |

## Internal-state premises

Premises about **your own** system — a flag's deployed value, whether a backfill
finished, whether a gate is already on, what a config actually contains. These
are the ones that get assumed rather than read, and each is refutable by a single
query, log grep or config dump. Name that read.

| # | Claim about our own system | The read that would refute it | Status |
|---|---|---|---|
| 1 | <the flag is off in production> | config dump on the running service | ✅ confirmed |
| 2 | <no rows carry the old shape> | `SELECT count(*) … WHERE …` | ✅ 0 rows |

## Approach

What you will change, in order. Name the files or modules. If you claim a
speedup, cite the timing:

**Measured-basis:** <what was timed, how many samples, p50 and range>. Not
derived by subtracting one stage from the total — an intercept absorbs everything
that does not scale.

## Flag coupling

Which flags gate this, what each defaults to, and what the system does when a
flag is off mid-rollout. A feature whose flag is never added to the deployment
lands dormant and looks like a bug months later.

## Variant matrix

Every arm this touches — chain, tenant, region, currency, plan, agent kind — and
what changes for each. An arm that changes nothing is written down as "no change",
never omitted: an omitted arm is indistinguishable from a forgotten one.

| Variant | Change | Verified by |
|---|---|---|
| <A> | <…> | <…> |
| <B> | no change | <why> |

## Parity impact

Which parallel implementations must move together (simulation ↔ live, preview ↔
apply, read ↔ write model, probe ↔ executor). If you touch only one side, write
**why parity does not break**. Silence reads as an omission.

## Activation Proof

The single observation that could only be true if this shipped **and took
effect**: a log line, a counter, a query result. Write it before implementing, and
say when you will look (T+30min is the usual first check). "The deploy succeeded"
is not activation proof; neither is "the column is populated".

## Pre-Mortem

It is two weeks later and this made things worse. What happened? List the two or
three most plausible stories and the observation that would catch each one early.

## Rollback

The exact steps, and whether they are safe to run under load.

## Shall continue to

At least three behaviours this must **not** break — the other variant, the
parallel path, the adjacent trigger. A fix with no stated blast radius has an
unbounded one.

1. …
2. …
3. …
