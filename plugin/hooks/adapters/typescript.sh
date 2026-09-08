#!/usr/bin/env bash
# Typecheck the project that owns the edited file. Args: <file> <project-root>
#
# There is no per-file typecheck in TypeScript worth trusting — a type error is
# usually reported in the file that consumes the change, not the one edited. So
# this is project-scoped, which makes the timeout in the caller load-bearing.
set -uo pipefail
fp="$1"
d="$(cd "$(dirname "$fp")" && pwd)"
while [ "$d" != "/" ] && [ ! -f "$d/tsconfig.json" ]; do d="$(dirname "$d")"; done
[ -f "$d/tsconfig.json" ] || exit 0
cd "$d" || exit 0
out=$(npx --no-install tsc --noEmit 2>&1); rc=$?
[ "$rc" -eq 0 ] && exit 0
printf '%s\n' "$out" | grep -E 'error TS[0-9]+' | head -30
exit 1
