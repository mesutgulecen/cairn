#!/usr/bin/env bash
# Syntax + lint the edited file. Args: <file> <project-root>
# Prefers ruff when available; falls back to a compile check, which catches the
# class of error an edit most often introduces.
set -uo pipefail
fp="$1"
if command -v ruff >/dev/null 2>&1; then
  out=$(ruff check "$fp" 2>&1); rc=$?
else
  out=$(python3 -m py_compile "$fp" 2>&1); rc=$?
fi
[ "$rc" -eq 0 ] && exit 0
printf '%s\n' "$out" | head -30
exit 1
