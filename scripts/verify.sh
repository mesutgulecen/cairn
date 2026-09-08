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

# expect_reason <want-rc> <name> <reason-substring> <cmd...>
# Exit code alone is a weak assertion: a guard can reject the right document for
# the wrong reason and still look calibrated. The reason is checked too.
expect_reason() {
  local want="$1" name="$2" needle="$3"; shift 3
  local out rc
  out=$("$@" 2>&1); rc=$?
  if [ "$rc" -eq "$want" ] && printf '%s' "$out" | grep -qF -- "$needle"; then
    printf '  ok   %-44s rc=%d\n' "$name" "$rc"
    pass=$((pass + 1))
  else
    printf '  FAIL %-44s rc=%d (want %d, reason ~ %s)\n' "$name" "$rc" "$want" "$needle"
    printf '%s\n' "$out" | sed 's/^/         | /' | head -12
    fail=$((fail + 1))
  fi
}

# expect_payload <want-rc> <name> <reason-substring|-> <hook> <file> [project-dir]
# Drives a stdin-payload hook the way the harness does. The payload goes through
# a file, not a pipe: a pipeline would put its own status where the hook's should
# be, which is the exact mistake these guards exist to prevent.
expect_payload() {
  local want="$1" name="$2" needle="$3" hook="$4" file="$5" projdir="${6:-$PWD}"
  local out rc tmp
  tmp=$(mktemp)
  python3 -c 'import json,sys; print(json.dumps({"tool_input": {"file_path": sys.argv[1]}}))' \
    "$file" > "$tmp"
  out=$(CLAUDE_PROJECT_DIR="$projdir" "$hook" < "$tmp" 2>&1); rc=$?
  rm -f "$tmp"
  if [ "$rc" -eq "$want" ] && { [ "$needle" = "-" ] || printf '%s' "$out" | grep -qF -- "$needle"; }; then
    printf '  ok   %-44s rc=%d\n' "$name" "$rc"
    pass=$((pass + 1))
  else
    printf '  FAIL %-44s rc=%d (want %d, reason ~ %s)\n' "$name" "$rc" "$want" "$needle"
    printf '%s\n' "$out" | sed 's/^/         | /' | head -12
    fail=$((fail + 1))
  fi
}

echo "sanitize-check calibration"
expect 1 "dirty fixture is rejected"  scripts/sanitize-check.sh fixtures/sanitize/dirty
expect 0 "clean fixture is accepted"  scripts/sanitize-check.sh fixtures/sanitize/clean
# Project names live in a deny file, not in the script: you should not have to
# edit a vendored scanner to add your own, and a deny list in a public repo is a
# directory of the names it exists to remove.
expect        0 "no deny file: a project name passes" \
  env CAIRN_DENY_FILE=/nonexistent scripts/sanitize-check.sh fixtures/sanitize/deny/mentions-company.md
expect_reason 1 "with a deny file: it is caught" "made-up-company" \
  scripts/sanitize-check.sh --deny fixtures/sanitize/deny/deny.txt fixtures/sanitize/deny/mentions-company.md

# A pattern with no line in the dirty fixture has never been shown to fire. It
# may be broken (a regex that cannot match its own target) and the suite would
# stay green regardless. Two were exactly that on the first run.
echo
echo "pattern coverage"
declared=$(grep -oE "^  '(\(\?i\))?[a-z0-9-]+\\|" scripts/sanitize-check.sh \
           | sed -E "s/^ *'(\(\?i\))?//; s/\\|$//" | sort -u)
exercised=$(scripts/sanitize-check.sh fixtures/sanitize/dirty 2>/dev/null \
            | sed -E 's/^LEAK\[([a-z0-9-]+)\].*/\1/' | sort -u)
uncovered=$(comm -23 <(printf '%s\n' "$declared") <(printf '%s\n' "$exercised"))
if [ -z "$uncovered" ]; then
  # Count the DECLARED patterns that fired, not every label the run emitted:
  # the filename check is not in the pattern list, and counting it produced a
  # cheerful "22/21".
  matched=$(comm -12 <(printf '%s\n' "$declared") <(printf '%s\n' "$exercised") | wc -l | tr -d ' ')
  printf '  ok   %-44s %s/%s patterns\n' "every pattern fires on the fixture" \
    "$matched" "$(printf '%s\n' "$declared" | wc -l | tr -d ' ')"
  pass=$((pass + 1))
else
  printf '  FAIL %-44s\n' "patterns never exercised by any fixture"
  printf '%s\n' "$uncovered" | sed 's/^/         | /'
  fail=$((fail + 1))
fi

echo
echo "plan-gate calibration"
G=components/hooks/plan-gate.sh
F=fixtures/plan-gate
expect_reason 2 "no discipline sections at all"      "missing 'Assumption Ledger'" \
  $G $F/must-fail/01-missing-sections.md
expect_reason 2 "describes the section, never opens it" "HEADING" \
  $G $F/must-fail/02-describes-without-heading.md
expect_reason 2 "an open probe survives into impl"   "OPEN [NEEDS PROBE] row(s)" \
  $G $F/must-fail/03-open-probe.md
expect_reason 2 "a multiplier with no direct timing" "Measured-basis" \
  $G $F/must-fail/04-unsourced-multiplier.md
expect 0 "complete plan passes (resolved probe, hex)" $G $F/must-pass/01-complete.md
expect 0 "a lower tier is not argued with"           $G $F/must-pass/02-lower-tier.md
# The gate looks for the sections the template provides. Nothing else keeps the
# two in step, and a gate that rejects its own template is how a process gets
# abandoned in week two.
expect 0 "the shipped plan template passes the gate" $G install/templates/templates/plan.md

echo
echo "migration-guard calibration"
M=components/hooks/migration-guard.sh
MP=fixtures/migration-guard/project
expect_payload 2 "up without a down"              "is missing"  $M $MP/migrations/0001_orders.up.sql   $MP
expect_payload 2 "table lacks the required column" "required column" $M $MP/migrations/0002_events.up.sql $MP
expect_payload 2 "column present, no row security" "ENABLE ROW LEVEL SECURITY" $M $MP/migrations/0003_notes.up.sql $MP
expect_payload 0 "compliant table passes"          -            $M $MP/migrations/0004_invoices.up.sql $MP
expect_payload 0 "exemption WITH a reason passes"  -            $M $MP/migrations/0005_catalog.up.sql  $MP
expect_payload 2 "exemption WITHOUT a reason is not one" "required column" $M $MP/migrations/0006_widgets.up.sql $MP

echo
echo "post-edit-lint calibration"
E=components/hooks/post-edit-lint.sh
expect_payload 2 "a syntax error is fed back"      "check failed" $E fixtures/post-edit-lint/broken.py
expect_payload 0 "valid source is silent"          -              $E fixtures/post-edit-lint/valid.py

# Four silent failure modes, four assertions. The drifted corpus carries exactly
# one of each, so a detector that stops working shows up as a count, not as a
# vague "still fails".
echo
echo "knowledge-lint calibration"
K=knowledge/knowledge_lint.py
kb() { $K --index "fixtures/knowledge/$1/notes" --corpus "fixtures/knowledge/$1/notes" \
             --entry "fixtures/knowledge/$1/notes/MEMORY.md" --check --quiet "${@:2}"; }
expect        0 "a healthy corpus passes"              kb clean
expect_reason 1 "link drift is found"     "1 fixable"           kb drifted --index-budget 200
expect_reason 1 "schema drift is found"   "schema     1"        kb drifted --index-budget 200
expect_reason 1 "an unreachable note is found" "1 unreachable"  kb drifted --index-budget 200
expect_reason 1 "an over-budget index is found" "OVER"          kb drifted --index-budget 200
expect        0 "a dangling forward link does NOT fail" kb forward-link

echo
echo "installer calibration"
expect 0 "the default run writes nothing"        scripts/test-install.sh dry-run
expect 0 "an empty project ends up working"      scripts/test-install.sh fresh
expect 0 "a pack installs its prompts AND rules" scripts/test-install.sh packs
expect 0 "a project with its own files keeps them" scripts/test-install.sh brownfield
expect 0 "a hostile config executes nothing"     scripts/test-install.sh hostile-config
expect 0 "a second run duplicates no hooks"      scripts/test-install.sh idempotent
expect 0 "existing settings and guide survive"   scripts/test-install.sh preserves
echo
echo "link check calibration"
expect_reason 1 "a renamed target is caught" "old-name.md" scripts/check-links.py fixtures/links/broken
expect 0 "external links and anchors are ignored"          scripts/check-links.py fixtures/links/clean

echo
echo "repository scan"
expect 0 "every relative link resolves"                    scripts/check-links.py
expect 0 "no secret in any historical blob"                scripts/sanitize-check.sh --history
# Our own project names are in .local/ (gitignored, never published), so this
# run also uses them when present. CI has only the built-in patterns; the local
# run is where an accidental mention of a source project gets caught.
if [ -f .local/sanitize-deny.txt ]; then
  expect 0 "repo is clean (incl. local deny list)" scripts/sanitize-check.sh --deny .local/sanitize-deny.txt
else
  expect 0 "repo is clean"              scripts/sanitize-check.sh
fi

# The README quotes this harness's output. A number typed into prose goes stale
# the moment an assertion is added, and a stale number in the first screen of a
# README is the kind of small wrong thing that makes a reader doubt the large
# right ones. So the claim is checked against the run.
# +1 for this check itself, so the number the README quotes is the number a
# reader will actually see printed at the end of the run.
total=$((pass + fail + 1))
claimed=$(grep -oE '^[0-9]+ passed, [0-9]+ failed' README.md 2>/dev/null | head -1 | cut -d' ' -f1)
if [ -n "$claimed" ] && [ "$claimed" != "$total" ]; then
  printf '  FAIL %-44s README says %s, harness ran %d\n' "README quotes the real assertion count" "$claimed" "$total"
  fail=$((fail + 1))
else
  printf '  ok   %-44s %d\n' "README quotes the real assertion count" "$total"
  pass=$((pass + 1))
fi

echo
printf '%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
