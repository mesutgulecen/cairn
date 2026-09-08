# Near misses (fixture — must PASS the scanner)

Everything here is legitimate public content that a greedy scanner would flag.

- Requires Go 1.24.0 and PostgreSQL 17.2; the CLI is at version 2.10.4.
- Install with `npm i -g @anthropic-ai/claude-code`; docs at https://github.com/anthropics.
- Supported chains in the web3 pack: Base, Ethereum, Solana, Arbitrum.
- RPC providers you can point the cost audit at: Alchemy, Helius, Ankr, QuickNode.
- Bind the dev server to 0.0.0.0 and browse http://localhost:3000.
- Read the env var name from your own config; this pack ships none of its own.
- A migration numbered 000367 and a test named TestParityBaselineHolds.
- Example public endpoint: https://api.github.com/repos/OWNER/REPO/pulls
- Loopback 127.0.0.1 and bind-all 0.0.0.0 are named without a waiver: the
  scanner's built-in allowlist must cover them.
- Documentation address 192.0.2.1 kept on purpose.  <!-- sanitize-ok: RFC 5737 example range, not a host we run -->
