# web3 sector pack

Five audits and three rules for systems that read from and write to chains. Opt
in at install time: `install/install.sh --packs general,web3 --apply`.

| Prompt | What it measures |
|---|---|
| `evm-chain-e2e-audit.md` | one EVM chain, discovery → close; carries the chain profile |
| `solana-e2e-audit.md` | the same body, a different §0 profile |
| `indexer-architecture-audit.md` | five unit-economics denominators + an integrity ladder |
| `rpc-cost-audit.md` | provider spend by consumer, and the two different limits |
| `onchain-order-latency-audit.md` | where the time goes, segment by segment |

| Rule | The failure it names |
|---|---|
| `chain-scoping.md` | the second chain, and the constants written for the first |
| `onchain-numeric-precision.md` | decimals, mantissa/exponent, float round-trips |
| `backtest-live-parity.md` | a simulation that is a second implementation, drifting |

## The chain-profile pattern

The two E2E prompts share one body and differ only in §0. When the **method**
changes, update both; when a **chain fact** changes, update only that file's §0.
Adding a third chain is a new §0, not a new prompt, which is the point: the
alternative is three documents that diverge silently, and the divergence is
discovered during an incident.

## What was removed before publishing

Chain names, provider names and contract standards are public and they stay,
an audit prompt that cannot name what it audits is useless. Removed:

- measured quotas, key counts, rate limits and cost figures from a specific
  deployment;
- thresholds, strategy parameters and gate configurations;
- host names, endpoints, internal work identifiers and schema snapshots;
- prompts covering product features rather than infrastructure.

What survives is the **method** and the **traps**: the numbers that remain are
the ones that teach: 1,780× from a constant matched across chains, 97.7–98.8% of
a call budget spent before the first provider, 82% of spend unattributed until a
one-line tag, 495 rows deleted because a mantissa was read without its exponent.
Those describe a *class* of mistake, not a deployment.
