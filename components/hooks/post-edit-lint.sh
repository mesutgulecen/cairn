#!/usr/bin/env bash
#
# PostToolUse — compile/typecheck the EDITED UNIT right after an edit, and feed
# a failure back to the model (exit 2) so it is fixed in the same turn.
#
# The point is the turn boundary. Broken code that survives to the next session
# is where fix-of-fix chains start: the next session sees the symptom without
# the intent, and patches the patch. Catching it while the reasoning is still
# in context is worth far more than the seconds it costs.
#
# Scoped to the edited package/file on purpose. A full test suite is not an
# edit-time gate: a gate slower than the developer's patience is a gate that
# gets removed. If it cannot be fast, it belongs in CI.
#
# Language support is an adapter per extension (adapters/<lang>.sh). An
# unknown extension is a no-op, never an error.
set -uo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
. "$here/lib/common.sh"

[ "$(cairn_config hooks.post_edit.enabled true)" = "false" ] && exit 0

fp="$(cairn_edited_file)"
[ -n "$fp" ] && [ -f "$fp" ] || exit 0

case "$fp" in
  *.go)                 adapter=go ;;
  *.ts|*.tsx)           adapter=typescript ;;
  *.py)                 adapter=python ;;
  *.rs)                 adapter=rust ;;
  *)                    exit 0 ;;
esac

script="$here/adapters/${adapter}.sh"
[ -x "$script" ] || exit 0

# An edit-time gate needs a ceiling. `timeout` is absent on some systems (and
# named gtimeout on others); without it we simply run unbounded rather than
# failing, because a missing utility must not block an edit.
limit="$(cairn_config_safe hooks.post_edit.timeout_seconds 60 '[0-9]{1,4}')"
runner=""
if command -v timeout >/dev/null 2>&1; then runner="timeout $limit"
elif command -v gtimeout >/dev/null 2>&1; then runner="gtimeout $limit"; fi

out=$($runner "$script" "$fp" "$(cairn_root)" 2>&1); rc=$?

# 124 is the timeout's own status: report it as advice, not as a code error.
if [ "$rc" -eq 124 ]; then
  echo "post-edit-lint: ${adapter} check exceeded ${limit}s and was stopped — not a verdict on the code." >&2
  exit 0
fi
if [ "$rc" -ne 0 ]; then
  echo "post-edit-lint: ${adapter} check failed after editing $(basename "$fp"):" >&2
  printf '%s\n' "$out" | head -30 >&2
  exit 2
fi
exit 0
