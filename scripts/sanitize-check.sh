#!/usr/bin/env bash
#
# Leak scanner — the FIRST gate in this repo, installed before any content moved.
#
# Cairn is extracted from two private production codebases. Everything published
# here passes through this scanner. It is deliberately a deny-list of the shapes
# that identify a *specific* deployment (hosts, keys, internal identifiers), not
# an attempt to detect "secrets" in general: public product names (Postgres, Go,
# Alchemy, Base, Solana) are allowed on purpose, because a sector pack is
# worthless if it cannot name the technology it audits.
#
# A scanner added after the content has moved is theatre: git history is not
# rewritten by a later commit. Hence F0.
#
# Usage:
#   sanitize-check.sh                 # scan the repo (default roots)
#   sanitize-check.sh <path> [...]    # scan specific files/dirs
#
# Exit: 0 = clean · 1 = findings
#
# Waiver: put `sanitize-ok: <reason>` on the same line (inside a comment).
# A waiver is a claim that the match is a false positive, not permission to
# publish a real identifier.
set -uo pipefail

# LABEL|REGEX  — extended regex, case-sensitive unless the pattern says otherwise.
PATTERNS=(
  # --- infrastructure identity -------------------------------------------
  'ipv4-literal|(^|[^0-9.])((25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\.){3}(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])([^0-9.]|$)'
  'ssh-target|ssh +[a-z_][a-z0-9_-]*@'
  'psql-target|(psql +-h|postgres(ql)?://[^ )"]*@)'
  'private-key-file|id_(ed25519|rsa|ecdsa)'
  'private-key-block|BEGIN [A-Z ]*PRIVATE KEY'
  'systemd-unit|(acme|beacon|example)[a-z0-9_-]*\.(service|timer)'

  # --- credentials --------------------------------------------------------
  'token-literal|\b(gh[pousr]_[A-Za-z0-9]{16,}|sk-[A-Za-z0-9]{20,}|xox[baprs]-[A-Za-z0-9-]{10,})'
  'rpc-url-key|https?://[a-z0-9.-]*(alchemy|helius|ankr|infura|quicknode)[a-z0-9.-]*(/[A-Za-z0-9_.-]+)*/[A-Za-z0-9_-]{16,}'
  'deployment-env-name|\b(ACME|BILLING|LEDGER)_[A-Z0-9_]{3,}\b'

  # --- our organisations, products and domains ----------------------------
  'internal-name|[Aa]cme|[Bb]eacon(App)?|ExampleLabs'
  'internal-domain|[a-z0-9-]+\.(xyz|internal|lan)\b'

  # --- internal issue / work identifiers ----------------------------------
  'issue-id|\b(ACME|SEC)-[0-9]{1,4}\b'
  'issue-id-e2e|\b(APP|SVC)-E2E-[0-9]{1,4}\b'

  # --- niche signals -------------------------------------------------------
  'example-chain-id|\b4663\b'
)

# Literals that match a pattern but identify no deployment. Stripped from a
# candidate line before the pattern is re-applied, so a line carrying BOTH an
# allowed literal and a real one still fails (filtering by whole lines would
# hide the real one).
#
# No \b here on purpose: BSD sed (macOS) does not implement it, and the first
# draft of this allowlist silently stripped nothing at all on this machine —
# the clean fixture is what surfaced it.
ALLOWED_LITERALS='(0\.0\.0\.0|127\.0\.0\.1|255\.255\.255\.255|localhost)'

roots=("$@")
if [ ${#roots[@]} -eq 0 ]; then
  roots=(.)
fi

# The scanner and its calibration fixtures contain the patterns themselves, so
# a repo-wide run must not scan them. The fixtures ARE scanned — explicitly, by
# scripts/verify.sh, which knows the verdict each one must produce.
EXCLUDES=(
  --exclude-dir=.git
  --exclude-dir=node_modules
  --exclude-dir=fixtures
  --exclude-dir=.local
  --exclude=sanitize-check.sh
)

findings=0
for entry in "${PATTERNS[@]}"; do
  label="${entry%%|*}"
  regex="${entry#*|}"
  hits=$(grep -rEnI "${EXCLUDES[@]}" -- "$regex" "${roots[@]}" 2>/dev/null | grep -v 'sanitize-ok:' || true)
  [ -z "$hits" ] && continue
  while IFS= read -r line; do
    stripped=$(printf '%s' "$line" | sed -E "s/${ALLOWED_LITERALS}//g")
    printf '%s' "$stripped" | grep -Eq -- "$regex" || continue
    printf 'LEAK[%s] %s\n' "$label" "$line"
    findings=$((findings + 1))
  done <<< "$hits"
done

if [ "$findings" -gt 0 ]; then
  printf '\nsanitize-check: %d finding(s) — nothing ships until these are redacted or waived.\n' "$findings" >&2
  exit 1
fi
echo "sanitize-check: clean (${#PATTERNS[@]} patterns over: ${roots[*]})"
exit 0
