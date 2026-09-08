# Calibration fixtures for `plugin/hooks/migration-guard.sh`

`project/` is a miniature repository: a `.cairn/config.json` that switches on the
configured invariants, and five migrations covering one case each.

Three must be rejected — a missing down file, a table without the required
column, a table with the column but no row level security — and two must pass:
a fully compliant table, and one exempted *with a written reason*. The exempt
case is the one worth having. An exemption mechanism nobody exercises is how a
guard quietly becomes optional.
