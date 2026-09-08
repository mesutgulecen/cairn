# Deploy runbook (fixture — must FAIL the scanner)

Every value below is reserved-for-documentation or fabricated. Nothing here
names a real system: an earlier draft used real work identifiers from the source
projects, in the one file the scanner is told to skip.

- App host: 203.0.113.7, database at 198.51.100.42 over the private link.
- Connect with `ssh deploy@bastion` then `psql -h db.example -U app`.
- The key lives at ~/.ssh/id_ed25519_prod.
- Restart with `systemctl restart acme-api.service`.
- Token for CI: ghp_AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA.
- RPC: https://base-mainnet.g.alchemy.com/v2/AAAAAAAAAAAAAAAAAAAAAAAA
- Set ACME_API_KEY in the environment before running.
- Pasted by mistake into a runbook: -----BEGIN OPENSSH PRIVATE KEY----- (truncated).
- AWS: AKIAIOSFODNN7EXAMPLE
- Google: AIzaSyA1234567890abcdefghijklmnopqrstuv
- npm: npm_abcdefghijklmnopqrstuvwxyz0123456789
- Stripe: sk_test_AAAAAAAAAAAAAAAA
- JWT: eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.dozjgNryP4J3jVmNHl0w5N
- Header: Authorization: Bearer abcdefghijklmnopqrstuvwxyz123456
- In code: api_key = "9f8e7d6c5b4a39281706abcdef123456"

Project-specific names (a company, an issue prefix, an internal domain) are NOT
tested here: they belong in a deny file, and `fixtures/sanitize/deny/` covers
that mechanism separately.
