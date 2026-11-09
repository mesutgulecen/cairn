#!/usr/bin/env bash
#
# q.sh calibration. One sub-command per property, so a break names itself.
#
#   rc-passthrough   the wrapped command's exit code is q.sh's exit code
#   surfaces-fail    a failure line buried in a long log is shown, with its line number
#   truncates        a 500-line log prints a bounded digest, and the FULL log is on disk
#   quiet-success    a clean run reports rc=0 and no failure section
#   empty-command    no command is a usage error, not a silent success
set -uo pipefail
cd "$(dirname "$0")/.."
Q="$PWD/components/bin/q.sh"
fail() { echo "    $*" >&2; exit 1; }

t=$(mktemp -d); trap 'rm -rf "$t"' EXIT
export Q_OUT_DIR="$t/out"

case "${1:-}" in

rc-passthrough)
  "$Q" a -- bash -c 'echo hi; exit 7' >/dev/null 2>&1; rc=$?
  [ "$rc" -eq 7 ] || fail "wrapped rc 7 came back as $rc"
  "$Q" b -- bash -c 'exit 0' >/dev/null 2>&1; rc=$?
  [ "$rc" -eq 0 ] || fail "wrapped rc 0 came back as $rc"
  ;;

surfaces-fail)
  out=$("$Q" f -- bash -c 'seq 1 200; echo "--- FAIL: TestSomething"; seq 201 400'); rc=$?
  [ "$rc" -eq 0 ] || fail "unexpected rc $rc"
  printf '%s' "$out" | grep -qF -- '201:--- FAIL: TestSomething' \
    || fail "the buried failure line (with its line number) was not surfaced"
  ;;

truncates)
  out=$("$Q" big -- bash -c 'seq 1 500'); rc=$?
  n=$(printf '%s\n' "$out" | wc -l | tr -d ' ')
  [ "$n" -le 40 ] || fail "digest was $n lines; it must stay bounded"
  printf '%s' "$out" | grep -qx '500' || fail "the tail (last line) is missing from the digest"
  log=$(printf '%s' "$out" | sed -n 's/.*log=//p' | head -1)
  [ -f "$log" ] || fail "the log path it printed does not exist: $log"
  full=$(wc -l <"$log" | tr -d ' ')
  [ "$full" -eq 500 ] || fail "the full log has $full lines, expected 500 — output was lost"
  ;;

quiet-success)
  out=$("$Q" ok -- bash -c 'echo all good'); rc=$?
  [ "$rc" -eq 0 ] || fail "rc $rc"
  printf '%s' "$out" | grep -qF 'failure lines' && fail "a clean run printed a failure section"
  printf '%s' "$out" | grep -qF 'rc=0' || fail "verdict (rc=0) missing"
  ;;

empty-command)
  "$Q" x -- >/dev/null 2>&1; rc=$?
  [ "$rc" -eq 2 ] || fail "no command must exit 2 (usage), got $rc"
  ;;

*) echo "usage: $0 rc-passthrough|surfaces-fail|truncates|quiet-success|empty-command" >&2; exit 2 ;;
esac
