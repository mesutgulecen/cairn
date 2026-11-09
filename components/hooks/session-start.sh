#!/usr/bin/env bash
#
# SessionStart — resume with the active work in context instead of a cold start.
#
# The expensive pattern this targets is the multi-session root-cause hunt: a
# session that begins by rediscovering what the previous one already knew. The
# cheapest fix is not a bigger context window, it is three facts at the top:
# what was committed, what the current phase is, and whether the knowledge base
# is healthy.
#
# Always exits 0. A hook failure must never stop a session from starting.
set -uo pipefail
# shellcheck source=lib/common.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

cd "$(cairn_root)" 2>/dev/null || exit 0

# Config values are validated, never trusted. Globs may contain path characters
# and wildcards and nothing else.
GLOB_RE='[A-Za-z0-9_*?./-]+'
progress_glob="$(cairn_config_safe hooks.session_start.progress_glob 'docs/plans/*/*-progress.md' "$GLOB_RE")"
plans_glob="$(cairn_config_safe hooks.session_start.plans_glob 'docs/plans/*/*.md' "$GLOB_RE")"

# The knowledge summary is chosen from a FIXED SET of tools, not supplied as a
# command line. This used to be `eval $kb_cmd` with the string taken straight
# from .cairn/config.json — which is arbitrary command execution, at session
# start, with no prompt, from a file that arrives with a git clone. Demonstrated
# by writing a file with `touch`; it could as easily have been anything else.
#
# There is no legitimate use for a free-form command here: everyone runs the
# knowledge linter. Configuration selects; it does not compose a shell line.
kb_tool="$(cairn_config_safe hooks.session_start.kb_tool 'knowledge_lint' '(knowledge_lint|none)')"
kb_path="$(cairn_config_safe hooks.session_start.kb_path 'knowledge/knowledge_lint.py' '[A-Za-z0-9_./-]+')"
case "$kb_path" in *..*) kb_path='knowledge/knowledge_lint.py' ;; esac

if [ -n "$(cairn_config hooks.session_start.kb_command '')" ]; then
  echo "cairn: hooks.session_start.kb_command is no longer supported (it allowed arbitrary command execution). Use kb_tool and kb_path." >&2
fi

recent=$(git log --oneline -5 2>/dev/null || true)

# Prefer an explicit progress file; fall back to the newest plan.
# shellcheck disable=SC2086
prog=$(ls -t $progress_glob 2>/dev/null | head -1 || true)
# shellcheck disable=SC2086
[ -z "${prog}" ] && prog=$(ls -t $plans_glob 2>/dev/null | head -1 || true)
proghead=""
[ -n "${prog}" ] && proghead=$(head -40 "${prog}" 2>/dev/null || true)

# The knowledge base usually lives outside the repo, so this cannot be a CI job.
# Invoked as an argument vector: no shell, so nothing in the path or the config
# is ever re-parsed as a command.
kb=""
if [ "$kb_tool" = "knowledge_lint" ] && [ -f "$kb_path" ]; then
  kb=$(python3 "$kb_path" --quiet 2>/dev/null || true)
fi


# Context budget advisory. Two things are loaded into EVERY session whether or not
# the task needs them: the project guide, and every rule whose `paths` is "**" (or
# absent). Both grow silently — nobody decides to make CLAUDE.md 69 KB, it
# accretes one dated paragraph at a time — and every turn pays for the whole of it.
# This only ADVISES (exit 0, text in the context); the numbers are heuristics
# from a measured case (a 69 KB guide ≈ 30k tokens), tunable in .cairn/config.json.
NUM_RE='[0-9]{3,7}'
guide_max="$(cairn_config_safe hooks.session_start.claude_md_max_bytes 15000 "$NUM_RE")"
rules_max="$(cairn_config_safe hooks.session_start.rules_always_on_max_bytes 20000 "$NUM_RE")"
budget=""
if [ -f CLAUDE.md ]; then
  gb=$(wc -c < CLAUDE.md | tr -d ' ')
  [ "$gb" -gt "$guide_max" ] && budget="CLAUDE.md is ${gb} bytes (budget ${guide_max}). It is loaded every session: move dated backstory and measurement narratives to a history file and keep the guide a router."
fi
if [ -d .claude/rules ]; then
  rb=0
  for rf in .claude/rules/*.md; do
    [ -f "$rf" ] || continue
    # Always-on = no `paths:` in the front matter, or a `**` entry in it.
    always=$(awk '
      NR==1 && $0!="---" { print "yes"; exit }
      NR>1 && $0=="---"  { print (haspaths && !star) ? "no" : "yes"; exit }
      /^paths:/          { haspaths=1 }
      /^[[:space:]]*-[[:space:]]*["'"'"']?\*\*["'"'"']?[[:space:]]*$/ { star=1 }
    ' "$rf")
    [ "$always" = "yes" ] && rb=$((rb + $(wc -c < "$rf" | tr -d ' ')))
  done
  if [ "$rb" -gt "$rules_max" ]; then
    budget="${budget:+$budget }Rules that load on every edit (paths \"**\" or none) total ${rb} bytes (budget ${rules_max}): narrow each rule's paths to the code its failure lives in."
  fi
fi

ctx="## Session continuity"$'\n\n'"### Recent commits"$'\n'"${recent:-(none)}"
[ -n "$prog" ] && ctx="${ctx}"$'\n\n'"### Active plan: ${prog}"$'\n'"${proghead}"
[ -n "${kb// }" ] && ctx="${ctx}"$'\n\n'"### Knowledge base"$'\n'"${kb}"
[ -n "$budget" ] && ctx="${ctx}"$'\n\n'"### Context budget"$'\n'"${budget}"

cairn_emit_context "SessionStart" "$ctx"
exit 0
