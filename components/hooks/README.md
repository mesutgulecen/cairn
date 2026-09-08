# Hooks

Five hooks, in two families.

## Blocking guards (exit 2 feeds the failure back to the model)

| Hook | Event | What it refuses |
|---|---|---|
| `plan-gate.sh` | invoked explicitly on a plan file | a high-risk plan whose premises are asserted rather than read |
| `post-edit-lint.sh` | `PostToolUse` | code that no longer compiles, before the turn ends |
| `migration-guard.sh` | `PostToolUse` | a migration you cannot reverse, or a table born without its invariant |

Each of the three ships with fixtures under `fixtures/` and is asserted by
`make verify`, both the exit code and the reason.

## Advisory (exit 0, adds context)

| Hook | Event | What it says |
|---|---|---|
| `session-start.sh` | `SessionStart` | last commits, the active plan, knowledge-base health |
| `env-drift.sh` | `PostToolUse` | a new configuration key exists in code but maybe not in the deployment |

Advisory hooks never block. A hook that can trap a session gets removed along
with every other hook in the file, so the ones that matter are the ones that
stay out of the way.

## Wiring

Merge `hooks.settings.json` into `.claude/settings.json`, adjusting paths. The
installer (F5) will do this for you, idempotently and with a backup; until then
it is a copy-paste.

## Configuration

Every hook reads optional overrides from `.cairn/config.json` at the project
root. An absent file, an absent key and malformed JSON all fall back to the
default: configuration is an override, never a precondition.

```jsonc
{
  "hooks": {
    "session_start": {
      "progress_glob": "docs/plans/*/*-progress.md",
      "plans_glob": "docs/plans/*/*.md",
      "kb_command": "knowledge/knowledge_lint.py --quiet"
    },
    "plan_gate": {
      "tier_pattern": "Tier:[^A-Za-z0-9]*K2",
      "required_sections": ["Assumption Ledger", "Activation Proof", "Pre-Mortem"],
      "internal_state_heading": "Internal-state premises",
      "probe_marker": "[NEEDS PROBE]",
      "measured_basis_pattern": "Measured-basis"
    },
    "post_edit": { "enabled": true, "timeout_seconds": 60 },
    "env_drift": {
      "config_file": "config",
      "deployment_target": "the production .env"
    },
    "migration_guard": {
      "required_column": "tenant_id uuid NOT NULL",
      "require_rls": true
    }
  }
}
```

`migration_guard` is the one to read twice: with no `required_column` and
`require_rls` false it still enforces the universal rule (every up has a
non-empty down) and nothing else. The table invariants are opt-in because only
your project knows what every table must carry.
