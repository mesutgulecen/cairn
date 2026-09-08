#!/usr/bin/env bash
#
# Guard calibration harness.
#
# Every guard in this repo is run against an input whose verdict is known: one
# it must reject, one it must accept. A guard with no failing fixture has not
# been shown to fire at all — see CONTRIBUTING.md.
#
# `$?` is captured into a variable on the line immediately after the command.
# Neither a command substitution nor a pipeline may sit between them: both reset
# it, and a harness that reports the opposite of the truth is worse than none.
set -uo pipefail
cd "$(dirname "$0")/.."

pass=0; fail=0

# expect <want-rc> <name> <cmd...>
expect() {
  local want="$1" name="$2"; shift 2
  local out rc
  out=$("$@" 2>&1); rc=$?
  if [ "$rc" -eq "$want" ]; then
    printf '  ok   %-44s rc=%d\n' "$name" "$rc"
    pass=$((pass + 1))
  else
    printf '  FAIL %-44s rc=%d (want %d)\n' "$name" "$rc" "$want"
    printf '%s\n' "$out" | sed 's/^/         | /' | head -12
    fail=$((fail + 1))
  fi
}

echo "sanitize-check calibration"
expect 1 "dirty fixture is rejected"  scripts/sanitize-check.sh fixtures/sanitize/dirty
expect 0 "clean fixture is accepted"  scripts/sanitize-check.sh fixtures/sanitize/clean

# A pattern with no line in the dirty fixture has never been shown to fire. It
# may be broken (a regex that cannot match its own target) and the suite would
# stay green regardless. Two were exactly that on the first run.
echo
echo "pattern coverage"
declared=$(grep -oE "^  '[a-z0-9-]+\\|" scripts/sanitize-check.sh | tr -d " '|" | sort -u)
exercised=$(scripts/sanitize-check.sh fixtures/sanitize/dirty 2>/dev/null \
            | sed -E 's/^LEAK\[([a-z0-9-]+)\].*/\1/' | sort -u)
uncovered=$(comm -23 <(printf '%s\n' "$declared") <(printf '%s\n' "$exercised"))
if [ -z "$uncovered" ]; then
  printf '  ok   %-44s %d/%d patterns\n' "every pattern fires on the fixture" \
    "$(printf '%s\n' "$exercised" | wc -l | tr -d ' ')" \
    "$(printf '%s\n' "$declared" | wc -l | tr -d ' ')"
  pass=$((pass + 1))
else
  printf '  FAIL %-44s\n' "patterns never exercised by any fixture"
  printf '%s\n' "$uncovered" | sed 's/^/         | /'
  fail=$((fail + 1))
fi

echo
echo "repository scan"
expect 0 "repo is clean"              scripts/sanitize-check.sh

echo
printf '%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
