# Quickstart: the first ten minutes

Assumes an existing project with git. Nothing here is irreversible; the installer
writes nothing until you pass `--apply`, and it never overwrites a file you
already have.

## 0 · Look before you install (1 min)

```sh
git clone https://github.com/mesutgulecen/cairn && cd cairn
./install/install.sh --target ~/projects/myapp
```

That is a dry run. It prints every path it would write and every one it would
skip because you already have it. Read the skip list. Those are the places your
project and cairn disagree, and you get to decide which of you is right.

## 1 · Install (1 min)

```sh
./install/install.sh --target ~/projects/myapp --apply --packs general
```

Add `,web3` if you read from chains, `,security` for the security audits. Roughly
50 files land: rules, hooks, commands, skills, templates, a docs skeleton, a
knowledge linter, and hook entries merged into `.claude/settings.json` (backed up
first).

## 2 · Make the two decisions the installer refused to make (5 min)

**Narrow the rule globs.** Every rule ships with `paths: ["**"]`, which is wrong
for your project on purpose:

```sh
$EDITOR ~/projects/myapp/.claude/rules/*.md   # point each `paths:` at the code where its failure lives
```

A rule that fires on every edit gets skimmed, and a skimmed rule protects
nothing. The six core rules are 26 KB together. That is the budget you are
spending each time they all match.

**Decide your migration invariant.** `.cairn/config.json` ships with the table
invariants off. The universal rule (every `up` has a non-empty `down`) already
works. If every table in your system must carry something (a tenant id, a
created-at, a soft-delete flag) say so:

```jsonc
"migration_guard": { "required_column": "tenant_id uuid NOT NULL", "require_rls": true }
```

## 3 · Prove it is live (1 min)

```sh
cd ~/projects/myapp
.claude/hooks/plan-gate.sh templates/plan.md      # → all discipline gates present
```

Then start Claude Code. The session-start hook prints your last commits, the
active plan (once you have one) and the knowledge base's health. If a section is
missing it is because there is nothing there yet. The hook never fails a session.

## 4 · Run one loop (2 min to start, the rest is your work)

```
/plan-new payment-retry K2
```

Fill the two ledgers **before** the approach. The second one, premises about
your own system, is the one that matters: a flag's deployed value, whether a
backfill finished, whether a gate is already on. Name the read that would refute
each. Mark anything unresolved `[NEEDS PROBE]`.

```
/plan-gate docs/plans/2026-09-08/payment-retry-2026-09-08.md
```

If it exits 2, it names the gap. Fix it, or lower the tier. K2 is for the money
path, a new integration, or a flag that changes production behaviour. Not
everything is K2, and padding a K1 into a K2 is how people learn to resent the
gate.

Then write code. The hooks work while you do: a broken build comes back inside
the same turn, a migration without a down file is refused, a new config key gets
a reminder that code merged is not code deployed.

After the deploy:

```
/deploy-verify
```

It asks three questions in order: is the new code running, does the environment
carry the config, and what single observation proves it took effect. A green
pipeline answers none of them.

## What to ignore at first

- **The web3 and security packs** unless you need them. Prompts you do not run
  are noise in your repository.
- **The knowledge linter** until you have notes. It is useful from about the
  twentieth note, not the second.
- **The case studies.** Read them the first time a guard here annoys you. Each
  one explains what it is protecting against, and one of them is the story of a
  guard that went green on the document that introduced the rule it enforced.

## When something here is wrong for you

Change it in a commit, with a fixture. `make verify` in this repository runs 35
assertions, and every guard has an input it must reject and one it must accept.
that is the whole method, and it applies to your changes too. A gate that gets
quietly worked around protects nothing.
