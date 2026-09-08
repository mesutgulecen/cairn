# Calibration fixtures for `scripts/sanitize-check.sh`

A guard that never fires is worse than no guard, and it looks identical to a
working one from the outside. So every guard in this repo ships with one input
it MUST reject and one it MUST accept, and `scripts/verify.sh` runs both.

- `dirty/` — must exit 1. Contains only reserved/documentation values
  (RFC 5737 `203.0.113.0/24`, fake tokens). Nothing real is checked in here.
- `clean/` — must exit 0. Deliberately full of *near misses*: semantic versions
  that look like IPv4, public product names, real public URLs, and one waived
  line. If the scanner is too greedy, this file is where it shows.

These directories are excluded from the repo-wide scan and passed to the
scanner explicitly by the harness.
