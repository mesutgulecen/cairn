#!/usr/bin/env bash
#
# Plan discipline gate — a TARGETED validator invoked on a plan file, not an
# automatic Stop hook.
#
#   plan-gate.sh <plan.md>
#     exit 0 = fine (not a gated plan, or every gate present)
#     exit 2 = a gated plan is missing a required gate (the gap is printed)
#
# Why not a Stop hook: plan directories are usually full of old, untracked
# drafts, and a Stop hook cannot reliably tell the plan being finalised from an
# unrelated one. It would eventually trap a session, and a hook that traps
# sessions gets deleted along with every other hook. Explicit invocation is
# exact and safe.
#
# WHAT THIS GATE IS FOR. A plan for a high-risk change (money path, new
# integration, a flag that alters production behaviour) must carry evidence, not
# only intentions. Four of the checks below exist because a plan that read
# perfectly went into implementation and had most of its items cancelled at
# execution time: their premises were wrong and one read would have shown it.
#
# EVERY CHECK HERE IS CALIBRATED. The history in each comment is not decoration
# — it records the draft that passed a document it should have rejected. See
# fixtures/plan-gate/, and CONTRIBUTING.md.
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
. "$here/lib/common.sh"

f="${1:-}"
if [ -z "$f" ] || [ ! -f "$f" ]; then
  echo "usage: plan-gate.sh <plan-file.md>" >&2
  exit 2
fi

tier_pattern="$(cairn_config hooks.plan_gate.tier_pattern 'Tier:[^A-Za-z0-9]*K2')"
probe_marker="$(cairn_config hooks.plan_gate.probe_marker '[NEEDS PROBE]')"
basis_pattern="$(cairn_config hooks.plan_gate.measured_basis_pattern 'Measured-basis')"

# Only the gated tier is enforced. A small change should not have to argue with
# a process built for a dangerous one.
if ! grep -qE "$tier_pattern" "$f"; then
  echo "plan-gate: $f is not a gated plan (no '$tier_pattern') — nothing to enforce."
  exit 0
fi

missing=""

# --- structural: the required sections exist --------------------------------
# Necessary, nowhere near sufficient: for a long time this WAS the whole gate,
# and a plan passed it while carrying five unresolved probes. Structure cannot
# detect content drift, which is why the three content checks follow.
default_sections=$'Assumption Ledger\nActivation Proof\nPre-Mortem'
sections="$(cairn_config hooks.plan_gate.required_sections "$default_sections")"
while IFS= read -r section; do
  [ -z "$section" ] && continue
  grep -qiF "$section" "$f" || missing="${missing}"$'\n'"  - missing '${section}'"
done <<< "$sections"

# --- A2: premises about your OWN system need their own ledger ---------------
# An assumption ledger is normally read as being about EXTERNAL services. Every
# cancelled item in the incident behind this gate was instead a claim about the
# system's own state — a flag's deployed value, whether a column was backfilled,
# whether a gate was already enabled. Each was refutable by a single read, and
# none of those reads was taken.
#
# It must be a HEADING, not a mention. The first draft grepped for the phrase
# anywhere and passed the very plan that introduced the rule, because that plan
# only DESCRIBED the section it was demanding. A guard can be vacuous and still
# go green; running it against a document you know should fail is the only way
# to find out.
internal_heading="$(cairn_config hooks.plan_gate.internal_state_heading 'Internal-state premises')"
grep -qiE "^#{2,5} .*${internal_heading}" "$f" \
  || missing="${missing}"$'\n'"  - missing an '${internal_heading}' HEADING (A2: a premise about your OWN system — a flag's value, a backfill, a gate already on — needs the read that would refute it)"

# --- A1: no OPEN probe may survive into implementation ----------------------
# The plan's own rule, enforced. A row counts as open only if it is a table row,
# carries the marker, and is neither ticked nor struck through: the first draft
# ("any row containing the marker") false-positived on a RESOLVED ledger cell
# that quoted the marker while reporting its answer. A gate that cries wolf on a
# correct document gets switched off, and that is how a process rule dies.
open_probes=$(grep '^|' "$f" | grep -F "$probe_marker" | grep -v '✅' | grep -v '~~' | wc -l | tr -d ' ')
if [ "${open_probes:-0}" != "0" ]; then
  missing="${missing}"$'\n'"  - ${open_probes} OPEN ${probe_marker} row(s) in the Assumption Ledger (A1: resolve them BEFORE implementation — the plan says so itself)"
fi

# --- A3: a numeric speedup claim needs a DIRECT measurement -----------------
# "RPC is 26% of the tick" came from the intercept of a regression fit, not from
# a timer on RPC. Measured directly it was 0.7%, and an entire phase had been
# sized on the wrong number. A fit, a difference and a residual are all
# attributions, not measurements: two components that scale with the same N are
# indistinguishable to a fit, and the intercept absorbs everything that does not
# scale. A claimed multiplier is unambiguous and greppable, so it is the trigger.
#
# Two calibration scars live in this one line:
#
#   * Hex literals are stripped first. Without that, `0x2fadcb1` (a block
#     cursor), an address and a topic hash all read as multipliers, and nearly
#     every plan in a month was rejected for a claim it never made.
#   * `grep -c`, never `grep -q`. Under `set -o pipefail`, `grep -q` exits at the
#     first match, the upstream `sed` dies of SIGPIPE (141), and 141 becomes the
#     pipeline's status — so the test read FALSE on exactly the documents that DO
#     claim a multiplier. This check was vacuous from the day pipefail was added.
#     `grep -c` reads to EOF and prints 0 while exiting 1, hence the `|| true`.
mult_hits=$(sed -E 's/0[xX][0-9a-fA-F]*//g' "$f" | grep -cE '[0-9][0-9,.]*[x×]' || true)
if [ "${mult_hits:-0}" -gt 0 ]; then
  grep -qiE "$basis_pattern" "$f" \
    || missing="${missing}"$'\n'"  - a speedup multiplier is claimed but no '${basis_pattern}:' line cites a DIRECT measurement of that component (A3: a fit, a difference or a residual is not a measurement of the part)"
fi

if [ -n "$missing" ]; then
  printf 'plan-gate: %s is missing required discipline gates:%s\n' "$f" "$missing" >&2
  echo "Add the sections, or lower the tier if this is not a high-risk change." >&2
  exit 2
fi
echo "plan-gate: $f — all discipline gates present."
exit 0
