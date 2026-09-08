# Prompt: Solana pipeline audit (end to end)

Sibling of `evm-chain-e2e-audit.md`. **The body is identical by design**. Only
§0 differs. When the shared method changes, update both files; when a chain fact
changes, update only that file's §0. This is the whole point of the chain-profile
pattern: one method, several instances, no divergence by accident.

| Argument | Default | Meaning |
|---|---|---|
| `window` | 24h | measurement window |
| `mode` | `read-only` | `read-only` \| `exercise` (explicit authorisation) |
| `output` | `docs/audits/<date>/solana-e2e-<date>.md` | report path |

## §0. Chain profile

| Field | Value |
|---|---|
| cluster | |
| commitment level used for reads, and for writes | |
| RPC providers and tier order; which are WebSocket | |
| subscription types in use (logs, program, account, slot) | |
| programs in scope, and how each instruction is decoded | |
| how a versioned transaction's address tables are resolved | |
| token decimals source (mint account, not assumed) | |
| retention of raw events | |
| schema snapshot date | |

Three facts worth stating explicitly because they differ from EVM and quietly
break code ported across:

1. **A transaction can succeed at one commitment and not exist at another.**
   Every read must state its commitment; an audit that does not is unreproducible.
2. **Instruction decoding is per-program, and a versioned transaction's accounts
   may live in a lookup table.** Code that indexes accounts positionally without
   resolving the table decodes a different instruction than the one that ran.
3. **Rate limiting is often the dominant cost, and it is not a tier.** In one
   trace, the limiter that runs *before* the first provider consumed 97.7–98.8%
   of the call budget while the providers themselves measured near zero. Time the
   pre-stage, not only the candidates you suspect.

## 1-7

As in `evm-chain-e2e-audit.md`, with two additions:

- **Slot gaps are not always your loss.** Skipped slots exist. Distinguish "the
  chain produced nothing" from "we missed it" before reporting a capture gap.
- **A WebSocket subscription that silently stops delivering looks exactly like a
  quiet market.** Assert liveness against an independent source, on a timer.
