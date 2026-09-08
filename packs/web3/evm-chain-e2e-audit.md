# Prompt: EVM chain pipeline audit (end to end)

Discovery → capture → decode → price → gate → execute → monitor → close, for one
EVM chain. Read-only against production unless the operator explicitly authorises
otherwise.

| Argument | Default | Meaning |
|---|---|---|
| `chain` | required | the chain to audit |
| `window` | 24h | measurement window (long enough to contain slow phases) |
| `mode` | `read-only` | `read-only` \| `exercise` (needs explicit authorisation) |
| `output` | `docs/audits/<date>/evm-e2e-<chain>-<date>.md` | report path |

## §0. Chain profile (the ONLY part that differs between sibling prompts)

Fill this before anything else. It is the whole reason one body can serve several
chains, and getting it wrong invalidates every measurement below.

| Field | Value |
|---|---|
| chain id / name | |
| block time (measured, not documented) | |
| RPC providers and tier order | |
| archive availability (which provider, how far back) | |
| discovery source (factory logs, pool watch, mempool, indexer) | |
| DEX / router contracts in scope | |
| quote assets and how each is priced | |
| native token decimals, and any non-18-decimal asset in scope | |
| retention: how long raw events are kept | |
| schema snapshot date | |

**Measure the block rate; do not read it from a document.** A rate derived from
your own stored timestamps is circular if those timestamps are themselves
suspect. Take it from the chain. One capacity plan was built on a block rate
3.3x too high because the figure came from a column that turned out to be
generated rather than observed, which made a hard cap look like comfortable
headroom.

## 1. Pre-flight

Establish, with evidence, before measuring anything:

- Which components are actually running (process list, recent log lines), not
  which are deployed.
- Every flag's live value. "Enabled in the code" is not enabled.
- The cursor or high-water mark for each ingesting worker, with its age.

## 2. Capture completeness

The central question: **what fraction of on-chain events did you store?**

Pick a sample of blocks in the window, fetch them independently, and diff against
what you stored. Report `captured / on-chain` with the sample size. Anything less
than a diff against the chain is a self-report: your own counters cannot detect
events you never saw.

Then find the gaps' *shape*. Losses concentrated in time point at restarts or
rate limits; losses concentrated by contract point at a filter; losses spread
evenly point at sampling or a race.

## 3. Freshness

`block timestamp → row committed`, p50 and p95, over the window. Report the
distribution, not the mean: a heavy tail is the interesting part, and a mean over
one is a summary of the population rather than of the slow cases.

If a worker spends part of each hour parked (rate-limited, backing off, waiting
on a lock), the throughput you measure during a run is not the throughput of the
system. Measure over wall-clock, including the parked time.

## 4. Pricing correctness

- Which quote asset does each pool use, and is each one **recognised**? An
  unrecognised quote priced as the familiar one produces plausible output marked
  valid, worse than an error, because nothing downstream can tell.
- Are constants belonging to another chain being compared by value? A reference
  asset matched by address across chains has mispriced pools by three orders of
  magnitude while reporting the result as valid.
- Sanity-check a handful of prices against an independent source. A pipeline that
  is internally consistent and externally wrong is the normal failure.

## 5. Gates

For each gate between a candidate and an execution: how many candidates entered,
how many each gate rejected, and with what reason. A gate that has **never**
rejected anything is either dead or unreached. Find out which, and say which.

Check the fail direction of every gate whose input can be missing. Missing data
must not read as a passing value.

## 6. Execution and exit

Confirm the executing path matches the probing path: a "this will work" verdict
proven by anything other than the operation the executor performs is not a
verdict. Then check exits: the trigger, the price it used, and whether a stale
or absent price can resolve in the favourable direction.

## 7. Report

Use `templates/audit.md`. Every number carries population, window and n. Findings
continue the previous run's numbering.
