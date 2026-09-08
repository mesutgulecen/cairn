---
description: Two implementations of one decision drift; change both or write down why not
paths:
  - "**"   # narrow to the modules that exist twice (simulation/live, preview/apply, read/write model)
---

# Parallel paths must move together

Some decisions are implemented twice on purpose: a simulation alongside the live
path, a preview alongside the apply, a read model alongside the write model, a
safety probe alongside the executor it protects. Parity between them is a
critical invariant that is usually enforced by nothing but discipline.

The cost of drift is not proportional to the size of the divergence. One
simulation reported **+97%** on a strategy that lost **99.76%** live: same
inputs, one missing rule on one side.

When you add or change a rule on a path that has a twin:

1. **Which side am I touching?** A rule added to the live path almost always
   needs its simulated twin, and the reverse. The exit checks, the retry policy,
   the price ladder, the dust write-off all drifted this way, one side at a time.
2. **If I touch only one side, why doesn't parity break?** Write the reason in
   the commit or the plan. "Live books a firm fill, the simulation uses a paper
   price" is a valid reason. Silence is not, because the next reader cannot
   distinguish a deliberate asymmetry from an omission.
3. **Does the probe use the same call as the executor?** A "this will work"
   verdict may only be proven by the *same* operation the executor will perform,
   at the same size. An indicative quote, a capability flag and a history of past
   successes prove nothing: a firm quote once showed a 99.96% loss on an asset
   the indicative probe had passed.
4. **Is the fallback direction-invariant?** When a value is missing or
   suspicious, the fallback must never resolve in the favourable direction. An
   absent price that defaults to "no loss" turns a missing measurement into a
   silent profit.
5. **Do both sides climb the same ladder?** If one path resolves an input through
   a chain of fallbacks (fresh → cached → persisted → give up), the twin needs
   the same rungs *in the same order*. A missing rung is not a small difference:
   one absent persisted rung drove a sparse-but-alive asset to a total-loss exit.

The durable form of this rule is a **shared case table**: one list of scenarios
with the expected outcome, asserted by both implementations. Prose parity rots;
a table that both sides import cannot.
