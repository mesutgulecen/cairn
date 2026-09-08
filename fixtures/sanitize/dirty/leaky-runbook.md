# Deploy runbook (fixture — must FAIL the scanner)

Every value below is reserved-for-documentation or fabricated. The work
identifiers and the chain id are invented: an earlier draft of this fixture used
real ones from the source projects, which meant the only file in the repository
carrying them was the one the scanner is told to skip.

- App host: 203.0.113.7, database at 198.51.100.42 over the private link.
- Connect with `ssh deploy@bastion` then `psql -h db.internal -U app`.
- The key lives at ~/.ssh/id_ed25519_prod.
- Restart with `systemctl restart acme-api.service`.
- Frontend is served from dashboard.example.xyz.
- Token for CI: ghp_AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA.
- RPC: https://base-mainnet.g.alchemy.com/v2/AAAAAAAAAAAAAAAAAAAAAAAA
- Set ACME_API_KEY and BILLING_SECRET_TOKEN.
- Tracks bug ACME-9991 and finding SEC-9992; see APP-E2E-9993 (invented numbers,
  real prefixes: the prefixes ARE the pattern under test, and they are already
  written in plain sight inside the scanner).
- Chain id 31337 is the second EVM chain.
- Pasted by mistake into a runbook: -----BEGIN OPENSSH PRIVATE KEY----- (truncated).
- AWS: AKIAIOSFODNN7EXAMPLE
- Google: AIzaSyA1234567890abcdefghijklmnopqrstuv
- npm: npm_abcdefghijklmnopqrstuvwxyz0123456789
- Stripe: sk_test_AAAAAAAAAAAAAAAA
- JWT: eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.dozjgNryP4J3jVmNHl0w5N
- Header: Authorization: Bearer abcdefghijklmnopqrstuvwxyz123456
- In code: api_key = "9f8e7d6c5b4a39281706abcdef123456"
