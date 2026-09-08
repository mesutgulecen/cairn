#!/usr/bin/env bash
# Build + vet the edited file's package only. Args: <file> <project-root>
set -uo pipefail
fp="$1"; root="$2"
module_dir="$(cd "$(dirname "$fp")" && pwd)"
# Walk up to the nearest go.mod: a repository may hold several modules.
d="$module_dir"
while [ "$d" != "/" ] && [ ! -f "$d/go.mod" ]; do d="$(dirname "$d")"; done
[ -f "$d/go.mod" ] || exit 0
rel="./${module_dir#"$d"/}"
cd "$d" || exit 0
out=$( { go build "$rel" && go vet "$rel"; } 2>&1 ); rc=$?
[ "$rc" -eq 0 ] && exit 0
printf '%s\n' "$out" | grep -E '\.go:[0-9]+|error|cannot|undefined|expected' | head -30
exit 1
