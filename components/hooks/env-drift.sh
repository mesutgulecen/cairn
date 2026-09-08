#!/usr/bin/env bash
#
# PostToolUse — a new configuration key in code is a feature that ships DORMANT
# unless the deployment environment gains it too.
#
# This is the merged-is-not-deployed class, and it is silent by construction:
# the build is green, the tests pass, the flag defaults to off, and the feature
# simply never runs in production. Nobody looks for a bug, because nothing
# broke. The reminder is cheap; the discovery is not.
#
# Non-blocking on purpose (exit 0 + context): the hook cannot know whether the
# deployment has been updated already, and a guard that blocks on something it
# cannot verify gets switched off.
set -uo pipefail
# shellcheck source=lib/common.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

fp="$(cairn_edited_file)"
[ -n "$fp" ] || exit 0

# Which file defines configuration, and how a key is read, are project facts.
watch="$(cairn_config hooks.env_drift.config_file 'config')"
case "$fp" in
  *"$watch"*) ;;
  *) exit 0 ;;
esac

pattern="$(cairn_config hooks.env_drift.key_pattern '(viper\.Get[A-Za-z]+|os\.Getenv|process\.env\.|getenv)\(?["'"'"']?([A-Z][A-Z0-9_]{2,})')"
target="$(cairn_config hooks.env_drift.deployment_target 'the deployment environment file')"

root="$(cairn_root)"
cd "$root" 2>/dev/null || exit 0

# Only ADDED lines, so an untouched key is not re-reported on every edit.
newkeys=$(git diff -- "$fp" 2>/dev/null | grep -E '^\+' \
          | grep -oE "$pattern" | grep -oE '[A-Z][A-Z0-9_]{2,}' | sort -u | tr '\n' ' ')
[ -n "${newkeys// }" ] || exit 0

cairn_emit_context "PostToolUse" \
"NEW CONFIG KEY(S): ${newkeys}— add them to ${target}, or the feature lands DORMANT (merged is not deployed). Record the rollout step in the plan, and verify after deploy with an activation proof: a log line or a query that could only be true if the key took effect."
exit 0
