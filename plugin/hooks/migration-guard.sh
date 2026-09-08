#!/usr/bin/env bash
#
# PostToolUse — a schema migration is where an invariant is cheapest to enforce
# and most expensive to retrofit.
#
# A table born without its invariant gets a repository, a use case and a handler
# written on top of it; narrowing it afterwards means changing migration, code
# and tests together, under production data. The boundary is set when the table
# is created or not at all.
#
# Two layers:
#
#   1. UNIVERSAL — every `*.up.sql` needs a non-empty `*.down.sql`. A migration
#      you cannot reverse is a deploy you cannot roll back, and an empty down
#      file is not a down file.
#
#   2. CONFIGURED — optional per-project invariants, off unless .cairn/config.json
#      asks for them:
#        hooks.migration_guard.required_column   e.g. "tenant_id uuid NOT NULL"
#        hooks.migration_guard.require_rls       true → ENABLE ROW LEVEL SECURITY
#                                                 plus at least one CREATE POLICY
#
# Exemptions are written WITH A REASON, never applied silently:
#
#   -- cairn-exempt(plans): platform catalogue, carries no tenant
#
# The reason matters more than the exemption: an unexplained skip is
# indistinguishable from an oversight six months later.
#
# exit 2 = violation (fed back to the model) · exit 0 = not a migration, or clean.
set -uo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
. "$here/lib/common.sh"

fp="$(cairn_edited_file)"
case "$fp" in
  *.up.sql) ;;
  *) exit 0 ;;
esac
[ -f "$fp" ] || exit 0

required_column="$(cairn_config hooks.migration_guard.required_column '')"
require_rls="$(cairn_config hooks.migration_guard.require_rls false)"

python3 - "$fp" "$required_column" "$require_rls" <<'PY'
import os, re, sys

path, required_column, require_rls = sys.argv[1], sys.argv[2].strip(), sys.argv[3] == "true"
src = open(path, encoding="utf-8").read()
name = os.path.basename(path)
problems = []

# --- 1. reversibility -------------------------------------------------------
down = path[: -len(".up.sql")] + ".down.sql"
if not os.path.isfile(down):
    problems.append(
        f"'{os.path.basename(down)}' is missing — every up needs a working down; "
        "a migration you cannot reverse is a deploy you cannot roll back."
    )
elif not open(down, encoding="utf-8").read().strip():
    problems.append(f"'{os.path.basename(down)}' is empty — a down file is not a placeholder.")

# --- 2. configured table invariants ----------------------------------------
if required_column or require_rls:
    exempt = {m.group(1).strip().lower()
              for m in re.finditer(r"--\s*cairn-exempt\(([^)]+)\)\s*:", src)}
    col_name = required_column.split()[0] if required_column else ""
    col_re = re.compile(r"^\s*" + re.escape(required_column).replace(r"\ ", r"\s+"),
                        re.IGNORECASE | re.MULTILINE) if required_column else None

    table_re = re.compile(
        r"CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?([A-Za-z_][\w.]*)\s*\(", re.IGNORECASE)

    for m in table_re.finditer(src):
        table = m.group(1).split(".")[-1]
        if table.lower() in exempt:
            continue

        # Body of this CREATE TABLE, by paren balance.
        i, depth = m.end() - 1, 0
        while i < len(src):
            if src[i] == "(":
                depth += 1
            elif src[i] == ")":
                depth -= 1
                if depth == 0:
                    break
            i += 1
        body = src[m.end():i]

        if col_re and not col_re.search(body):
            problems.append(
                f"`{table}`: required column `{required_column}` is absent. If this table is "
                f"genuinely outside the invariant, say why: `-- cairn-exempt({table}): <reason>`"
            )
            continue  # the RLS questions are meaningless without the column

        if require_rls:
            if not re.search(
                rf"ALTER\s+TABLE\s+(?:ONLY\s+)?(?:[\w.]+\.)?{re.escape(table)}\b[^;]*"
                r"ENABLE\s+ROW\s+LEVEL\s+SECURITY", src, re.IGNORECASE):
                problems.append(
                    f"`{table}`: no `ENABLE ROW LEVEL SECURITY` — a WHERE clause in application "
                    "code is a convention, not a boundary."
                )
            if not re.search(
                rf"CREATE\s+POLICY\s+[\w\"]+\s+ON\s+(?:[\w.]+\.)?{re.escape(table)}\b",
                src, re.IGNORECASE):
                problems.append(
                    f"`{table}`: row level security with no `CREATE POLICY ... ON {table}` closes "
                    "the table to everyone — a silent production outage rather than a leak."
                )

if problems:
    sys.stderr.write(f"migration-guard: {name} did not pass:\n")
    for p in problems:
        sys.stderr.write(f"  - {p}\n")
    sys.exit(2)
sys.exit(0)
PY
