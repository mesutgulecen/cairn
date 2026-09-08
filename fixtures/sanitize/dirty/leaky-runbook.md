# Deploy runbook (fixture — must FAIL the scanner)

Every value below is reserved-for-documentation or fabricated.

- App host: 203.0.113.7, database at 198.51.100.42 over the private link.
- Connect with `ssh deploy@bastion` then `psql -h db.internal -U app`.
- The key lives at ~/.ssh/id_ed25519_prod.
- Restart with `systemctl restart acme-api.service`.
- Frontend is served from dashboard.example.xyz.
- Token for CI: ghp_AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA.
- RPC: https://base-mainnet.g.alchemy.com/v2/AAAAAAAAAAAAAAAAAAAAAAAA
- Set ACME_API_KEY and BILLING_SECRET_TOKEN.
- Tracks bug ACME-999 and finding SEC-123; see APP-E2E-77.
- Chain id 31337 is the second EVM chain.
- Pasted by mistake into a runbook: -----BEGIN OPENSSH PRIVATE KEY----- (truncated).
