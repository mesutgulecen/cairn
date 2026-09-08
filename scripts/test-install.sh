#!/usr/bin/env bash
#
# Installer calibration. Four properties, one sub-command each, so a break names
# itself instead of reporting "install failed".
#
#   dry-run    the default writes NOTHING
#   fresh      an empty project ends up with a working setup, end to end
#   idempotent a second run adds no duplicate hooks
#   preserves  an existing settings.json keeps its own keys and its own hooks
#
# Each exits 0 on success, 1 with a message on failure.
set -uo pipefail
cd "$(dirname "$0")/.."
SRC="$PWD"

fail() { echo "    $*" >&2; exit 1; }
have() { [ -e "$1/$2" ] || fail "missing: $2"; }

case "${1:-}" in

dry-run)
  t=$(mktemp -d)
  "$SRC/install/install.sh" --target "$t" >/dev/null 2>&1; rc=$?
  [ "$rc" -eq 0 ] || { rm -rf "$t"; fail "dry run exited $rc"; }
  n=$(find "$t" -mindepth 1 | wc -l | tr -d ' ')
  rm -rf "$t"
  [ "$n" -eq 0 ] || fail "dry run created $n path(s) — it must write nothing"
  ;;

fresh)
  t=$(mktemp -d)
  "$SRC/install/install.sh" --apply --target "$t" >/dev/null 2>&1; rc=$?
  [ "$rc" -eq 0 ] || { rm -rf "$t"; fail "install exited $rc"; }

  for p in .claude/hooks/plan-gate.sh .claude/hooks/lib/common.sh \
           .claude/hooks/adapters/python.sh .claude/commands/plan-gate.md \
           .claude/rules/fix-discipline.md knowledge/knowledge_lint.py \
           templates/plan.md docs/README.md docs/decisions docs/plans \
           docs/audits docs/runbooks docs/prompts/general/code-review.md \
           CLAUDE.md .cairn/config.json .claude/settings.json; do
    have "$t" "$p" || { rm -rf "$t"; exit 1; }
  done
  [ -x "$t/.claude/hooks/plan-gate.sh" ] || { rm -rf "$t"; fail "hooks are not executable"; }

  rules=$(find "$t/.claude/rules" -name '*.md' | wc -l | tr -d ' ')
  [ "$rules" -eq 6 ] || { rm -rf "$t"; fail "expected 6 rules, found $rules"; }

  grep -q 'session-start.sh' "$t/.claude/settings.json" \
    || { rm -rf "$t"; fail "settings.json has no hook entries"; }

  # End to end: the INSTALLED gate must accept the INSTALLED template. Checking
  # that files landed proves copying works; this proves the setup works.
  ( cd "$t" && CLAUDE_PROJECT_DIR="$t" ./.claude/hooks/plan-gate.sh templates/plan.md ) >/dev/null 2>&1
  rc=$?
  rm -rf "$t"
  [ "$rc" -eq 0 ] || fail "the installed gate rejected the installed template (rc=$rc)"
  ;;

idempotent)
  t=$(mktemp -d)
  "$SRC/install/install.sh" --apply --target "$t" >/dev/null 2>&1
  before=$(grep -c '"command"' "$t/.claude/settings.json")
  out=$("$SRC/install/install.sh" --apply --target "$t" 2>&1); rc=$?
  after=$(grep -c '"command"' "$t/.claude/settings.json")
  rm -rf "$t"
  [ "$rc" -eq 0 ] || fail "second run exited $rc"
  [ "$before" -eq "$after" ] || fail "hooks duplicated: $before → $after"
  printf '%s' "$out" | grep -q 'already up to date' || fail "second run did not report an up-to-date merge"
  ;;

preserves)
  t=$(mktemp -d); mkdir -p "$t/.claude"
  cat > "$t/.claude/settings.json" <<'JSON'
{
  "permissions": { "allow": ["Bash(ls:*)"] },
  "outputStyle": "Explanatory",
  "hooks": {
    "SessionStart": [
      { "hooks": [ { "type": "command", "command": "echo mine" } ] }
    ]
  }
}
JSON
  echo "# my own guide" > "$t/CLAUDE.md"
  "$SRC/install/install.sh" --apply --target "$t" >/dev/null 2>&1; rc=$?
  [ "$rc" -eq 0 ] || { rm -rf "$t"; fail "install exited $rc"; }

  grep -q 'Bash(ls:\*)' "$t/.claude/settings.json" || { rm -rf "$t"; fail "unrelated key was dropped"; }
  grep -q 'echo mine'   "$t/.claude/settings.json" || { rm -rf "$t"; fail "existing hook was dropped"; }
  grep -q 'session-start.sh' "$t/.claude/settings.json" || { rm -rf "$t"; fail "our hook was not added"; }
  [ -e "$t/.claude/settings.json.bak" ] || { rm -rf "$t"; fail "no backup was taken"; }
  grep -q '^# my own guide' "$t/CLAUDE.md" || { rm -rf "$t"; fail "existing CLAUDE.md was overwritten"; }
  rm -rf "$t"
  ;;

*) echo "usage: test-install.sh <dry-run|fresh|idempotent|preserves>" >&2; exit 2 ;;
esac
exit 0
