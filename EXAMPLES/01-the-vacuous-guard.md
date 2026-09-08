# 1. A guard that could not fail

## What happened

A planning process had a rule: a high-risk plan must carry a section listing its
premises about the team's *own* system: a flag's deployed value, whether a
backfill finished, whether a gate was already on, because those are the premises
that get assumed rather than read.

Prose in a checklist had not been enough, so the rule was given a script. The
script grepped the plan for the phrase "internal-state premises". It went green
on the very document that introduced the rule.

That document *described* the section. It did not contain one.

Two more checks in the same script had the same shape:

- A check for unresolved probe markers fired on a **resolved** ledger row,
  because the row quoted the marker while reporting its answer. A gate that
  cries wolf on a correct document gets switched off, and then the two checks
  that worked go off with it.
- A check requiring a direct measurement behind any claimed speedup had been
  **silently dead** since the day `set -o pipefail` was added to the script. It
  used `sed … | grep -q`; `grep -q` exits at the first match, `sed` dies of
  SIGPIPE (141), and `pipefail` promotes 141 to the pipeline's status. So the
  test read *false* on exactly the documents that did claim a multiplier. It was
  a check that only worked when there was nothing to catch.

## Why it was invisible

All three were green. There is no observable difference between a guard that
passes because the input is clean and a guard that passes because it cannot fail.
Every code review of that script read it as correct, because read as prose it
*is* correct. The defect is in what the tools do, not in what the author meant.

## What it cost

One sprint's plan went into implementation carrying five unresolved probes,
against its own written rule. Four of its seven items were cancelled during
execution because their premises were wrong, and each of those premises was
refutable by a single query.

## What stops it now

Every guard in this repository ships with an input it **must reject** and an
input it **must accept**, and `make verify` runs both. The leak scanner goes
further and asserts that *every one of its patterns* fires on the dirty fixture,
which immediately found two patterns that could not match anything at all.

`CONTRIBUTING.md` states the rule plainly: a guard is not accepted without a
failing fixture. The calibration history stays in the comments of
`plugin/hooks/plan-gate.sh`, because in this repository that history is the
product.
