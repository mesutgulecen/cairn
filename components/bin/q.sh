#!/usr/bin/env bash
#
# q.sh — run a noisy command, keep the FULL output in a file, put only a digest
# into the conversation.
#
#   .claude/bin/q.sh <label> -- <command...>
#   .claude/bin/q.sh tests -- make test
#
# Why: raw build/test/lint output is the largest avoidable context cost in a
# session. Every turn re-reads the whole conversation, so a 4,000-line test log
# pasted once is paid for again on every later turn. This keeps what a decision
# needs (the verdict, the failures, the tail) and leaves the rest on disk where
# `grep -n` and a ranged read can reach it.
#
# Contract (calibrated by scripts/test-qsh.sh):
#   - the exit code of <command> is q.sh's exit code, unchanged;
#   - lines that look like failures are surfaced (first 40), with line numbers;
#   - the tail (last 25 lines) is printed;
#   - the full log path is printed, so nothing is ever lost.
#
# Output dir: $Q_OUT_DIR, else ${TMPDIR:-/tmp}/cairn-q.
set -u
label="${1:-run}"; shift || true
[ "${1:-}" = "--" ] && shift
[ $# -gt 0 ] || { echo "usage: q.sh <label> -- <command...>" >&2; exit 2; }

dir="${Q_OUT_DIR:-${TMPDIR:-/tmp}/cairn-q}"
mkdir -p "$dir" || exit 2
# Seconds + pid: two runs in the same second must not share a log.
log="$dir/$(date +%H%M%S)-$$-${label}.log"

"$@" >"$log" 2>&1
rc=$?   # captured on the line right after the command: nothing may sit between

echo "== q: $label rc=$rc lines=$(wc -l <"$log" | tr -d ' ') log=$log"
errs=$(grep -nE '(^|[^A-Za-z])(FAIL|FAILED|ERROR|Error:|error:|panic:|Traceback|AssertionError)' "$log" | head -40)
if [ -n "$errs" ]; then
  echo "-- failure lines (first 40):"
  echo "$errs"
fi
echo "-- tail (last 25):"
tail -25 "$log"
exit "$rc"
