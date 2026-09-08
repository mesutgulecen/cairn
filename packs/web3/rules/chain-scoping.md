---
description: The second chain breaks every assumption written for the first: selectors, constants, defaults, payloads
paths:
  - "**/worker/**"
  - "**/onchain/**"
  - "**/adapter/**"
  - "**/repository/**"
---

# Chain scoping

The web3 instance of `the-second-instance`. Adding a second EVM chain breaks
every place that assumed "an `0x` address means *our* chain", and the breakage is
silent because addresses, hashes and topics are byte-identical across chains.
In one codebase this class produced 32 separate fixes in a single month.

Before editing chain-dispatching code, ask:

1. **Chain-unscoped selector?** Does a query, repository method or worklist select
   tokens, positions or pools **without a chain filter**, so a row from chain B
   gets processed against chain A's RPC, constants or contracts? Reconciliation,
   exit monitoring, holder tracking and lifecycle cleanup were all this, every
   one written when the filter would have been a no-op.
2. **Constant leak?** Is a package-level constant (the wrapped native token, a
   chain id, the canonical stablecoin) compared by value rather than resolved per
   chain? A pricing helper that matched chain A's wrapped-native address mispriced
   chain B's pools by roughly **1,780×** and marked the result valid.
3. **Default branch falls through to chain A?** A `switch chain` whose unknown case
   lands on the original path fails OPEN into the wrong chain. On a money path,
   prefer fail-closed: skip and alert.
4. **Per-chain enablement missing?** New tagging, enrichment or caching usually
   needs an explicit "enabled for chain B" beside the one it already has. Without
   it chain B receives empty data and a downstream gate **starves**: no error,
   just a gate that never passes.
5. **Quote basis fail-unsafe?** A pool whose quote asset is not recognised must
   fail closed. Priced as the familiar quote it produces garbage that is marked
   valid, and a floating-rate quote asset is a third basis, not a variant of the
   two you have.
6. **Payload carries a hash but not the chain?** Any event, notification or API
   response shipping a transaction hash or token address **must** ship the chain
   too. Otherwise the consumer infers it, and infers the original, producing
   links that point confidently at the wrong explorer. This bit one system twice:
   a feed, then the entire notification layer.

## Enforce it, do not remember it

A lint over the files that name a chain identifier is worth more than this
document. Two cautions from building one:

- **A file naming exactly ONE chain is the dangerous shape, not the safe one.**
  A rule requiring two or more identifiers excluded two of the eleven files a
  human had already flagged.
- **Keep the hand-curated list as a union base** and pin with a test that it is
  not a subset: the riskiest files may name no chain identifier at all, so no
  derived rule can ever reach them.
