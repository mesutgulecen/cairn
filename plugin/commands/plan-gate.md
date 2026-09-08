---
description: Validate a plan against the discipline gates before implementation
argument-hint: <path/to/plan.md>
---

Run `.claude/hooks/plan-gate.sh $1` and report the result verbatim.

If it exits 2, do not start implementing. Fix what it names, or lower the tier if
this genuinely is not a high-risk change. If you believe the gate is wrong, say
so explicitly and explain why — a gate that gets quietly worked around protects
nothing, and the fix is to change the gate, in a commit, with a fixture.
