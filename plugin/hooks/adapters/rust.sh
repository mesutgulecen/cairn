#!/usr/bin/env bash
# cargo check for the crate owning the edited file. Args: <file> <project-root>
set -uo pipefail
fp="$1"
d="$(cd "$(dirname "$fp")" && pwd)"
while [ "$d" != "/" ] && [ ! -f "$d/Cargo.toml" ]; do d="$(dirname "$d")"; done
[ -f "$d/Cargo.toml" ] || exit 0
cd "$d" || exit 0
out=$(cargo check --quiet --message-format short 2>&1); rc=$?
[ "$rc" -eq 0 ] && exit 0
printf '%s\n' "$out" | grep -E '^error|\.rs:[0-9]+' | head -30
exit 1
