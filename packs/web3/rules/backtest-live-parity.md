---
description: A backtest and the live path are two implementations of one decision
paths:
  - "**/backtest/**"
  - "**/simulation/**"
  - "**/executor/**"
  - "**/strategy/**"
---

# Backtest ↔ live parity

The web3 instance of `parallel-paths-parity`, and the most expensive place it
applies: a strategy that reports **+97%** simulated can lose **99.76%** live from
a single rule present on one side only. The simulation is not a test of the
strategy; it is a second implementation of it, and it drifts like any other.

1. **Every gate exists on both sides, or the asymmetry is written down.** Entry
   filters, exit triggers, cooldowns, position limits, dust handling. If the
   simulation lacks one, say why in the commit — silence reads as an omission,
   and six months later nobody can tell which it was.
2. **The price ladder must have the same rungs, in the same order.** If live
   resolves a price through fresh quote → cache → persisted snapshot → give up,
   the simulation needs all four. A missing rung is not a small difference: one
   absent persisted rung drove a sparse-but-alive asset to a total-loss exit that
   never happened in reality.
3. **A stale price may not book a profit.** Take-profit must fire on a verifiable
   price only. Stop-loss may defer on a stale price; the dead-asset backstop is
   the one exit allowed to act on an unverifiable one. Anything else lets a
   missing measurement resolve in the favourable direction.
4. **Costs belong in the simulated fill, not in a footnote.** Fees, slippage and
   priority costs modelled outside the profit calculation produce a backtest that
   is right about direction and wrong about survival.
5. **The probe must be the executor's own call.** "This is sellable" proven by an
   indicative price, by bytecode, or by someone else having sold it before, is
   not proof. A firm quote at the real size once showed a 99.96% loss on an asset
   an indicative probe had passed.
6. **Simulated time must not see the future.** Any lookup keyed by "latest"
   rather than "as of the simulated instant" leaks hindsight, and the leak
   always improves the result — which is why it is never noticed by the person
   who benefits from it.
