#!/usr/bin/env bash
#
# Context-budget advisory calibration (session-start.sh). Each case builds a
# throwaway project and runs the REAL hook against it.
#
#   bloated-guide     a 20 KB CLAUDE.md is flagged
#   lean-guide        a 2 KB CLAUDE.md is not
#   always-on-rules   rules with paths "**" (or no paths) over budget are flagged
#   scoped-rules      the SAME bytes with narrowed paths are not
#   config-override   a raised budget in .cairn/config.json silences it
#   hostile-budget    a non-numeric budget falls back to the default, executes nothing
set -uo pipefail
cd "$(dirname "$0")/.."
SRC="$PWD"
fail() { echo "    $*" >&2; exit 1; }

mk() { # mk <dir>: project with the real hooks and a neutral rule set
  mkdir -p "$1/.claude/hooks" "$1/.claude/rules"
  cp -R "$SRC/components/hooks/." "$1/.claude/hooks/"
  chmod +x "$1/.claude/hooks/"*.sh
  git -C "$1" init -q 2>/dev/null
}
run() { ( cd "$1" && CLAUDE_PROJECT_DIR="$1" ./.claude/hooks/session-start.sh 2>/dev/null ); }
body() { head -c "$2" /dev/zero | tr '\0' 'x' > "$1"; }   # exactly N bytes of filler
rule() { # rule <dir> <name> <bytes> <paths-block|none>
  { echo '---'; echo 'description: filler'
    if [ "$4" != none ]; then echo 'paths:'; printf '%s\n' "$4"; fi
    echo '---'; head -c "$3" /dev/zero | tr '\0' 'x'; echo; } > "$1/.claude/rules/$2.md"
}

t=$(mktemp -d); trap 'rm -rf "$t"' EXIT

case "${1:-}" in

bloated-guide)
  mk "$t"; body "$t/CLAUDE.md" 20000
  run "$t" | grep -qF 'CLAUDE.md is 20000 bytes' || fail "a 20000-byte guide was not flagged"
  ;;

lean-guide)
  mk "$t"; body "$t/CLAUDE.md" 2000
  run "$t" | grep -qF 'Context budget' && fail "a 2000-byte guide was flagged"
  exit 0
  ;;

always-on-rules)
  mk "$t"
  rule "$t" a 9000 '  - "**"'
  rule "$t" b 9000 none
  rule "$t" c 9000 "  - '**'"
  out=$(run "$t")
  printf '%s' "$out" | grep -qF 'Rules that load on every edit' || fail "27 KB of always-on rules was not flagged"
  ;;

scoped-rules)
  mk "$t"
  rule "$t" a 9000 '  - "src/**"'
  rule "$t" b 9000 '  - "backend/internal/**"'
  rule "$t" c 9000 '  - "apps/**"'
  run "$t" | grep -qF 'Context budget' && fail "path-scoped rules were counted as always-on"
  exit 0
  ;;

config-override)
  mk "$t"; body "$t/CLAUDE.md" 20000
  mkdir -p "$t/.cairn"
  echo '{"hooks":{"session_start":{"claude_md_max_bytes":"30000"}}}' > "$t/.cairn/config.json"
  run "$t" | grep -qF 'Context budget' && fail "a raised budget did not silence the advisory"
  exit 0
  ;;

hostile-budget)
  mk "$t"; body "$t/CLAUDE.md" 20000
  mkdir -p "$t/.cairn"
  echo "{\"hooks\":{\"session_start\":{\"claude_md_max_bytes\":\"1; touch $t/PWNED\"}}}" > "$t/.cairn/config.json"
  out=$(run "$t")
  [ -e "$t/PWNED" ] && fail "a hostile budget value executed"
  printf '%s' "$out" | grep -qF 'CLAUDE.md is 20000 bytes' || fail "fell back to no budget instead of the default"
  ;;

*) echo "usage: $0 bloated-guide|lean-guide|always-on-rules|scoped-rules|config-override|hostile-budget" >&2; exit 2 ;;
esac
