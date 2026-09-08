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

progress_glob="$(cairn_config hooks.session_start.progress_glob 'docs/plans/*/*-progress.md')"
plans_glob="$(cairn_config hooks.session_start.plans_glob 'docs/plans/*/*.md')"
kb_cmd="$(cairn_config hooks.session_start.kb_command 'knowledge/knowledge_lint.py --quiet')"

recent=$(git log --oneline -5 2>/dev/null || true)

# Prefer an explicit progress file; fall back to the newest plan.
# shellcheck disable=SC2086
prog=$(ls -t $progress_glob 2>/dev/null | head -1 || true)
# shellcheck disable=SC2086
[ -z "${prog}" ] && prog=$(ls -t $plans_glob 2>/dev/null | head -1 || true)
proghead=""
[ -n "${prog}" ] && proghead=$(head -40 "${prog}" 2>/dev/null || true)

# The knowledge base usually lives outside the repo, so this cannot be a CI job.
kb=""
if [ -n "$kb_cmd" ]; then
  # shellcheck disable=SC2086
  kb=$(eval $kb_cmd 2>/dev/null || true)
fi

ctx="## Session continuity"$'\n\n'"### Recent commits"$'\n'"${recent:-(none)}"
[ -n "$prog" ] && ctx="${ctx}"$'\n\n'"### Active plan: ${prog}"$'\n'"${proghead}"
[ -n "${kb// }" ] && ctx="${ctx}"$'\n\n'"### Knowledge base"$'\n'"${kb}"

cairn_emit_context "SessionStart" "$ctx"
exit 0
