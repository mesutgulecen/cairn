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
           .claude/skills/plan-authoring/SKILL.md \
           .claude/skills/audit-authoring/SKILL.md \
           .claude/skills/memory-notes/SKILL.md \
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

packs)
  t=$(mktemp -d)
  "$SRC/install/install.sh" --apply --target "$t" --packs general,web3,security >/dev/null 2>&1; rc=$?
  [ "$rc" -eq 0 ] || { rm -rf "$t"; fail "install exited $rc"; }
  have "$t" "docs/prompts/web3/indexer-architecture-audit.md" || { rm -rf "$t"; exit 1; }
  have "$t" "docs/prompts/general/code-review.md" || { rm -rf "$t"; exit 1; }
  # A pack's own rules belong with the core rules, not under docs/prompts/.
  have "$t" ".claude/rules/chain-scoping.md" || { rm -rf "$t"; exit 1; }
  have "$t" ".claude/rules/dependency-drift.md" || { rm -rf "$t"; exit 1; }
  have "$t" "docs/prompts/security/app-security-audit.md" || { rm -rf "$t"; exit 1; }
  rules=$(find "$t/.claude/rules" -name '*.md' | wc -l | tr -d ' ')
  rm -rf "$t"
  [ "$rules" -eq 10 ] || fail "expected 6 core + 3 web3 + 1 security rule, found $rules"
  ;;

brownfield)
  # An empty directory cannot produce a collision, so `fresh` cannot detect one.
  # This is a project that already has its own versions of things cairn ships:
  # two rules with the SAME FILENAMES, a settings.json with its own hooks, its
  # own CLAUDE.md, and a docs tree with real content in it. Nothing of the
  # project's may be lost, and nothing of cairn's may be silently skipped
  # without saying so.
  t=$(mktemp -d)
  mkdir -p "$t/.claude/rules" "$t/docs/plans/2026-01-01" "$t/templates"
  echo "# our own fix discipline, different content" > "$t/.claude/rules/fix-discipline.md"
  echo "# our own session hygiene"                   > "$t/.claude/rules/session-hygiene.md"
  echo "# our own project guide"                     > "$t/CLAUDE.md"
  echo "# a real plan we already wrote"              > "$t/docs/plans/2026-01-01/a-plan.md"
  echo "# our own plan template"                     > "$t/templates/plan.md"
  cat > "$t/.claude/settings.json" <<'JSON'
{ "permissions": { "allow": ["Bash(ls:*)"] },
  "hooks": { "SessionStart": [ { "hooks": [ { "type": "command", "command": "echo mine" } ] } ] } }
JSON

  out=$("$SRC/install/install.sh" --apply --target "$t" 2>&1); rc=$?
  [ "$rc" -eq 0 ] || { rm -rf "$t"; fail "install exited $rc"; }

  # 1. Nothing of the project's was overwritten.
  grep -q "our own fix discipline" "$t/.claude/rules/fix-discipline.md" || { rm -rf "$t"; fail "an existing rule was overwritten"; }
  grep -q "our own project guide"  "$t/CLAUDE.md"                       || { rm -rf "$t"; fail "an existing CLAUDE.md was overwritten"; }
  grep -q "our own plan template"  "$t/templates/plan.md"               || { rm -rf "$t"; fail "an existing template was overwritten"; }
  grep -q "a real plan"            "$t/docs/plans/2026-01-01/a-plan.md" || { rm -rf "$t"; fail "existing docs content was lost"; }
  grep -q "echo mine"              "$t/.claude/settings.json"           || { rm -rf "$t"; fail "an existing hook was dropped"; }
  grep -q "Bash(ls:\*)"            "$t/.claude/settings.json"           || { rm -rf "$t"; fail "an unrelated settings key was dropped"; }

  # 2. The collisions were REPORTED, not silently skipped. A skip nobody is told
  #    about is how a user ends up believing they have a guard they do not have.
  for name in "fix-discipline.md (exists)" "CLAUDE.md (exists)" "templates/plan.md (exists)"; do
    printf '%s' "$out" | grep -qF "$name" || { rm -rf "$t"; fail "collision not reported: $name"; }
  done

  # 3. What did NOT collide still landed.
  have "$t" ".claude/rules/measurement-discipline.md" || { rm -rf "$t"; exit 1; }
  have "$t" ".claude/hooks/plan-gate.sh"              || { rm -rf "$t"; exit 1; }
  have "$t" "docs/prompts/general/code-review.md"     || { rm -rf "$t"; exit 1; }
  rm -rf "$t"
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

*) echo "usage: test-install.sh <dry-run|fresh|packs|brownfield|idempotent|preserves>" >&2; exit 2 ;;
esac
exit 0
