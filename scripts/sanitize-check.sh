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

  # --- generic secret material (not deployment-specific) ------------------
  # These are here because a scanner whose only job is "our identifiers" gets
  # adopted as a leak gate by everyone who installs it. Measured 2026-09-08:
  # of eight common secret classes, this file caught one. That gap is not a
  # theoretical exposure for us; it is a false assurance for a user.
  'aws-access-key|\bAKIA[0-9A-Z]{16}\b'
  'gcp-api-key|\bAIza[0-9A-Za-z_-]{35}\b'
  'npm-token|\bnpm_[A-Za-z0-9]{36}\b'
  'stripe-key|\bsk_(live|test)_[A-Za-z0-9]{16,}'
  'jwt|\beyJ[A-Za-z0-9_-]{8,}\.eyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}'
  'auth-header|Authorization:[[:space:]]*(Bearer|Basic)[[:space:]]+[A-Za-z0-9._~+/=-]{16,}'
  '(?i)assigned-secret|(api[_-]?key|secret|passwd|password|access[_-]?token)[[:space:]]*[:=][[:space:]]*["'"'"'][^"'"'"']{12,}["'"'"']'

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

# Files that should never be committed at all, whatever is inside them. A
# content pattern cannot catch an empty-looking .env or a binary key.
# `.env.example` / `.env.sample` / `.env.template` are things projects commit on
# purpose. A rule that forbids "anything starting with .env" would reject them,
# and a scanner that cries wolf on a correct repository gets switched off — so
# the list names the real environment files instead of a prefix.
FORBIDDEN_NAMES='^(\.env|\.env\.(local|dev|development|test|staging|prod|production)|id_(rsa|dsa|ecdsa|ed25519)|.*\.(pem|p12|pfx|keystore|jks))$'

HISTORY=0
EXPLICIT=0
roots=()
for arg in "$@"; do
  case "$arg" in
    --history) HISTORY=1 ;;
    *) roots+=("$arg"); EXPLICIT=1 ;;
  esac
done
if [ ${#roots[@]} -eq 0 ]; then
  roots=(.)
fi

# A secret deleted from the working tree is still in the history, and history is
# what a clone hands to a stranger. This mode materialises every text blob any
# commit ever contained and scans that instead.
if [ "$HISTORY" -eq 1 ]; then
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  git rev-list --all --objects 2>/dev/null | while read -r sha obj; do
    [ -z "$obj" ] && continue
    case "$obj" in
      */fixtures/*|fixtures/*) continue ;;
      *.md|*.sh|*.py|*.json|*.yml|*.yaml|*.txt|*.tmpl|*.toml|*.cfg|*.ini) ;;
      *) continue ;;
    esac
    git cat-file blob "$sha" > "$tmp/${sha:0:8}-$(basename "$obj")" 2>/dev/null || true
  done
  echo "sanitize-check: scanning $(ls "$tmp" | wc -l | tr -d ' ') historical blob(s)"
  roots=("$tmp")
fi

# The scanner and its calibration fixtures contain the patterns themselves, so
# a repo-wide run must not scan them. The fixtures ARE scanned — explicitly, by
# scripts/verify.sh, which knows the verdict each one must produce.
EXCLUDES=(
  --exclude-dir=.git
  --exclude-dir=node_modules
  --exclude-dir=fixtures
  --exclude-dir=.local
  # The glob has a wildcard because --history materialises blobs as
  # `<sha>-sanitize-check.sh`: the scanner's own pattern list matches its own
  # patterns, and a bare basename exclude misses the renamed copies.
  --exclude=*sanitize-check.sh
)

findings=0
for entry in "${PATTERNS[@]}"; do
  label="${entry%%|*}"
  regex="${entry#*|}"
  # A pattern may ask for case-insensitivity with an `(?i)` prefix on its LABEL;
  # grep -E has no inline flag, so it becomes a -i on the invocation.
  ci=""
  case "$label" in
    '(?i)'*) ci="-i"; label="${label#(?i)}" ;;
  esac
  hits=$(grep -rEnI $ci "${EXCLUDES[@]}" -- "$regex" "${roots[@]}" 2>/dev/null | grep -v 'sanitize-ok:' || true)
  [ -z "$hits" ] && continue
  while IFS= read -r line; do
    stripped=$(printf '%s' "$line" | sed -E "s/${ALLOWED_LITERALS}//g")
    printf '%s' "$stripped" | grep -Eq $ci -- "$regex" || continue
    printf 'LEAK[%s] %s\n' "$label" "$line"
    findings=$((findings + 1))
  done <<< "$hits"
done

# Forbidden filenames, checked separately: this is about the name, not the bytes.
while IFS= read -r f; do
  base="$(basename "$f")"
  if printf '%s' "$base" | grep -qE "$FORBIDDEN_NAMES"; then
    printf 'LEAK[forbidden-filename] %s\n' "$f"
    findings=$((findings + 1))
  fi
done < <(
  if [ "$EXPLICIT" -eq 1 ]; then
    # Given an explicit root, scan it whole — that is how the fixtures get
    # checked. Excluding fixtures unconditionally would blind this check to its
    # own calibration, which is the failure this repository is about.
    find "${roots[@]}" -type f -not -path '*/.git/*' 2>/dev/null
  else
    find "${roots[@]}" -type f -not -path '*/.git/*' -not -path '*/fixtures/*' -not -path '*/.local/*' 2>/dev/null
  fi)

if [ "$findings" -gt 0 ]; then
  printf '\nsanitize-check: %d finding(s) — nothing ships until these are redacted or waived.\n' "$findings" >&2
  exit 1
fi
echo "sanitize-check: clean (${#PATTERNS[@]} patterns over: ${roots[*]})"
exit 0
