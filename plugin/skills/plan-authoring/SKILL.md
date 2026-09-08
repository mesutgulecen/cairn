---
name: plan-authoring
description: Write or repair a plan that survives the discipline gate — pick the tier, fill the assumption ledgers with reads rather than beliefs, and state an activation proof before implementing. Use when starting a plan, when the plan gate rejects one, or when a change is large enough that someone asks "what's the plan".
---

# Authoring a plan

A plan's job is not to describe the work. It is to make the premises visible
*before* they are expensive. Most cancelled work is not badly executed; it is
correctly executed against a premise nobody read.

## 1 — Pick the tier honestly, and downgrade rather than pad

- **K0** — one sentence, no behaviour change. No plan needed; say what you are
  doing and do it.
- **K1** — a bug fix with a known cause. Problem, approach, what must not break.
- **K2** — the money path, a new integration or instance, or a flag that changes
  production behaviour. This is the gated tier.

Deleting a section you did not need is honest. **Leaving it empty is not** — an
empty section reads as considered and dismissed. If you find yourself writing
ceremony, the tier is wrong.

## 2 — Fill BOTH ledgers before writing the approach

The **Assumption Ledger** holds premises about the outside world: a provider's
behaviour, a limit, a format. Each says how it was checked.

The **Internal-state premises** section holds premises about your own system —
a flag's deployed value, whether a backfill finished, whether a gate is already
on, what a config actually contains. These are the ones that get assumed instead
of read, and each is refutable by a single query, log grep or config dump.
**Name that read.** If you cannot name it, the premise is not a premise, it is a
hope.

Mark anything unresolved `[NEEDS PROBE]`, and do not start implementing while one
is open. That rule is yours; the gate only enforces what you already decided.

## 3 — Do not claim a multiplier you did not time

If the plan promises a speedup, add a `Measured-basis:` line saying what was
timed, over how many samples, with p50 and range. A fit, a difference and a
residual are attributions, not measurements: two components that scale with the
same n are indistinguishable to a fit, and the intercept absorbs everything that
does not scale.

## 4 — Write the activation proof BEFORE implementing

The single observation that could only be true if this shipped **and took
effect** — a log line, a counter, a query result — plus when you will look. A
green pipeline is not activation proof. Neither is a populated column: it may
have been filled by the old path, a backfill, or a default.

## 5 — Name the blast radius

A variant matrix where an unchanged arm is written down as "no change" rather
than omitted (an omitted arm is indistinguishable from a forgotten one), a parity
section for any decision implemented twice, and at least three "shall continue
to" neighbours. A fix with no stated blast radius has an unbounded one.

## 6 — Run the gate

`.claude/hooks/plan-gate.sh <plan.md>`. If it rejects the plan, fix what it names
or lower the tier. If you believe the gate is wrong, say so explicitly and change
the gate in a commit with a fixture — a gate that gets quietly worked around
protects nothing.

Template: `templates/plan.md`.
