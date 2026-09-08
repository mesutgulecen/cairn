# Prompt: on-chain order latency, by segment

Where the time goes between "a reason to act exists" and "the transaction is
confirmed". The point is attribution: a total is not actionable, and a total
minus a part is not a measurement of the rest.

| Argument | Default | Meaning |
|---|---|---|
| `chain` | all | which chains to segment |
| `side` | both | `buy` \| `sell` \| `both` |
| `output` | `docs/audits/<date>/order-latency-<date>.md` | report path |

## Segments

Time each one **separately**, with its own timer. Do not derive any segment by
subtraction.

| # | Segment | From → to |
|---|---|---|
| 1 | signal | event observed → decision made |
| 2 | admission | decision → cleared rate limiter / lock / inflight cap |
| 3 | quote | request → route or price returned |
| 4 | build | parameters → signed transaction |
| 5 | submit | signed → accepted by a node |
| 6 | inclusion | accepted → included in a block |
| 7 | confirm | included → final at your required commitment |

Publish `accounted` against `total`. When they diverge, you have found a stage
you did not know existed, which is the usual outcome, and the most valuable one.
In one trace the dominant consumer was the admission stage, before any of the
candidates anyone had proposed.

## Rules

1. **A serial probe does not represent concurrent load.** Latency measured one
   call at a time tells you nothing about the queue that forms under real
   traffic. Say which you measured.
2. **Report p50 and p95 per segment.** The mean of a segment that occasionally
   blocks describes neither the normal case nor the bad one.
3. **Verify the timer's scope before trusting it.** A deferred stop-call placed
   inside a conditional block can be function-scoped rather than block-scoped, so
   one segment silently absorbs the following ones: the exact mis-attribution
   this audit exists to prevent, produced by the instrument. Calibrate against a
   case with a known answer: one slow stage, one fast one, and the fast one must
   stay fast.
4. **Nonce and ordering constraints are part of the measurement.** If sends share
   a per-account nonce they are serial no matter how much concurrency you add;
   report the constraint alongside the number.
