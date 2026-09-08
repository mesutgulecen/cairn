#!/usr/bin/env bash
#
# cairn installer.
#
# Three properties, in the order they matter:
#
#   1. DRY RUN BY DEFAULT. It prints what it would do and writes nothing until
#      you pass --apply. An installer that modifies a repository on first
#      invocation is one people run once, in a scratch directory, and never
#      trust again.
#   2. IT NEVER OVERWRITES. An existing file is reported as skipped, not
#      replaced. --force exists and says so loudly.
#   3. THE SETTINGS MERGE IS IDEMPOTENT. Hook entries are matched by command, so
#      running this twice does not give you two copies of every hook — which is
#      the classic way an install script turns a working setup into a slow one.
#
# Usage:
#   install/install.sh [--apply] [--target DIR] [--packs a,b] [--rules a,b|all]
#                      [--force] [--no-settings]
set -uo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="$PWD"
APPLY=0
FORCE=0
DO_SETTINGS=1
PACKS="general"
RULES="all"

while [ $# -gt 0 ]; do
  case "$1" in
    --apply) APPLY=1 ;;
    --force) FORCE=1 ;;
    --no-settings) DO_SETTINGS=0 ;;
    --target) TARGET="$2"; shift ;;
    --packs) PACKS="$2"; shift ;;
    --rules) RULES="$2"; shift ;;
    -h|--help) sed -n '2,30p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
  shift
done

[ -d "$TARGET" ] || { echo "target is not a directory: $TARGET" >&2; exit 2; }
TARGET="$(cd "$TARGET" && pwd)"
[ "$TARGET" = "$SRC" ] && { echo "refusing to install cairn into itself" >&2; exit 2; }

created=0; skipped=0
say() { printf '  %-9s %s\n' "$1" "$2"; }

# copy_file <src> <dest-relative>
copy_file() {
  local src="$1" rel="$2" dest="$TARGET/$2"
  if [ -e "$dest" ] && [ "$FORCE" -eq 0 ]; then
    say "skip" "$rel (exists)"; skipped=$((skipped + 1)); return
  fi
  say "$([ "$APPLY" -eq 1 ] && echo write || echo would)" "$rel"
  created=$((created + 1))
  [ "$APPLY" -eq 1 ] || return
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  [ -x "$src" ] && chmod +x "$dest"
  return 0
}

echo "cairn → $TARGET"
[ "$APPLY" -eq 1 ] || echo "(dry run — nothing is written; pass --apply)"
echo

echo "rules"
for f in "$SRC"/plugin/rules/*.md; do
  b="$(basename "$f")"; [ "$b" = "README.md" ] && continue
  case "$RULES" in
    all) ;;
    *) case ",$RULES," in *",${b%.md},"*) ;; *) continue ;; esac ;;
  esac
  copy_file "$f" ".claude/rules/$b"
done

echo
echo "hooks"
for f in "$SRC"/plugin/hooks/*.sh; do copy_file "$f" ".claude/hooks/$(basename "$f")"; done
copy_file "$SRC/plugin/hooks/lib/common.sh" ".claude/hooks/lib/common.sh"
for f in "$SRC"/plugin/hooks/adapters/*.sh; do copy_file "$f" ".claude/hooks/adapters/$(basename "$f")"; done

echo
echo "commands"
for f in "$SRC"/plugin/commands/*.md; do
  b="$(basename "$f")"; [ "$b" = "README.md" ] && continue
  copy_file "$f" ".claude/commands/$b"
done

echo
echo "knowledge"
copy_file "$SRC/knowledge/knowledge_lint.py" "knowledge/knowledge_lint.py"
copy_file "$SRC/knowledge/note-schema.md" "knowledge/note-schema.md"

echo
echo "templates and docs skeleton"
for f in "$SRC"/install/templates/templates/*.md; do copy_file "$f" "templates/$(basename "$f")"; done
copy_file "$SRC/install/templates/docs/README.md" "docs/README.md"
for d in decisions plans audits runbooks; do
  if [ -d "$TARGET/docs/$d" ]; then
    say "skip" "docs/$d/ (exists)"; skipped=$((skipped + 1))
  else
    say "$([ "$APPLY" -eq 1 ] && echo write || echo would)" "docs/$d/"
    created=$((created + 1))
    [ "$APPLY" -eq 1 ] && mkdir -p "$TARGET/docs/$d"
  fi
done
# The project guide is the one file a project is most likely to already have,
# and the one it would hurt most to lose.
copy_file "$SRC/install/templates/CLAUDE.md.tmpl" "CLAUDE.md"

echo
echo "prompt packs"
IFS=',' read -r -a pack_list <<< "$PACKS"
for pack in "${pack_list[@]}"; do
  [ -d "$SRC/packs/$pack" ] || { say "skip" "$pack (no such pack)"; continue; }
  for f in "$SRC/packs/$pack"/*.md; do copy_file "$f" "docs/prompts/$pack/$(basename "$f")"; done
done

echo
echo "configuration"
if [ -e "$TARGET/.cairn/config.json" ] && [ "$FORCE" -eq 0 ]; then
  say "skip" ".cairn/config.json (exists)"; skipped=$((skipped + 1))
else
  say "$([ "$APPLY" -eq 1 ] && echo write || echo would)" ".cairn/config.json"
  created=$((created + 1))
  if [ "$APPLY" -eq 1 ]; then
    mkdir -p "$TARGET/.cairn"
    cat > "$TARGET/.cairn/config.json" <<'JSON'
{
  "hooks": {
    "session_start": {
      "progress_glob": "docs/plans/*/*-progress.md",
      "plans_glob": "docs/plans/*/*.md",
      "kb_command": "knowledge/knowledge_lint.py --quiet"
    },
    "post_edit": { "enabled": true, "timeout_seconds": 60 },
    "env_drift": { "config_file": "config", "deployment_target": "the deployed environment file" },
    "migration_guard": { "required_column": "", "require_rls": false }
  }
}
JSON
  fi
fi

if [ "$DO_SETTINGS" -eq 1 ]; then
  echo
  echo "harness settings"
  if [ "$APPLY" -eq 1 ]; then
    python3 "$SRC/install/merge_settings.py" \
      "$TARGET/.claude/settings.json" "$SRC/plugin/hooks/hooks.settings.json"
  else
    say "would" ".claude/settings.json (merge hook entries, backup first)"
  fi
fi

echo
printf '%d file(s) %s, %d skipped.\n' "$created" \
  "$([ "$APPLY" -eq 1 ] && echo written || echo pending)" "$skipped"

if [ "$APPLY" -eq 1 ]; then
  cat <<'NEXT'

Two things the installer deliberately did NOT do for you:

  1. The rules ship with `paths: ["**"]`, which is wrong for your project on
     purpose. Narrow each one to the code where its failure actually lives — a
     rule that fires on every edit gets skimmed, and a skimmed rule protects
     nothing.
  2. `.cairn/config.json` has migration_guard's table invariants switched off.
     Only your project knows what every table must carry.

Then run: .claude/hooks/plan-gate.sh templates/plan.md
NEXT
fi
exit 0
