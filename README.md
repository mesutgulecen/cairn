# cairn

*A cairn is a stack of stones left on a trail so the next traveller does not get
lost.* This is the same idea for engineering with Claude Code.

Most repositories in this space distribute **content**: agent collections, prompt
megapacks, command libraries. Cairn distributes **process**: the handful of
mechanisms that decided, across two production codebases, whether an AI-assisted
change was correct or merely plausible.

```sh
git clone https://github.com/mesutgulecen/cairn && cd cairn
./install/install.sh --target /path/to/your/project              # dry run
./install/install.sh --target /path/to/your/project --apply
./install/install.sh --target /path/to/your/project --packs general,web3,security --apply
```

New here? [QUICKSTART.md](QUICKSTART.md) walks the first ten minutes.

The installer never overwrites an existing file, backs up `.claude/settings.json`
before merging into it, and matches hook entries by command so a second run adds
nothing.

## The idea

**A guard nobody has watched fail has not been shown to work.** It is
indistinguishable from a guard that always passes, and the second kind is worse
than none: it buys confidence and delivers nothing.

So every guard here ships with an input it must reject and an input it must
accept, and `make verify` runs both:

```
$ make verify
sanitize-check calibration      dirty rejected · clean accepted
pattern coverage                every pattern fires on the fixture (14/14)
plan-gate calibration           4 rejected for the right reason · 3 accepted
migration-guard calibration     4 rejected · 2 accepted
post-edit-lint calibration      broken source fed back · valid source silent
knowledge-lint calibration      one of each decay mode found · forward link tolerated
installer calibration           dry run writes nothing · idempotent · brownfield · preserves
manifest calibration            missing owner rejected · missing path rejected
hostile config                  nothing executes · the session still starts
history scan                    no secret in any blob any commit ever held
link check calibration          renamed target caught · code fences ignored
40 passed, 0 failed
```

Several of those assertions exist because the thing they check was, at some
point, silently doing nothing. The leak scanner had two patterns that could not
match anything at all. The plan gate had a check that was dead from the day
`pipefail` was added. The installer dropped a pack's rules without a word.

## What you get

| | |
|---|---|
| **6 rules** | injected at edit time by path. Each opens with the measurement that produced it, a window or a ratio or a count, because a rule that says "measure carefully" is advice, and one that says "1.49x over 25 minutes was 1.043x over 9.32 hours" changes behaviour. |
| **5 hooks** | three that block (plan discipline, edit-time compile, migration invariants) and two that advise (session continuity, config drift). |
| **3 skills** | `plan-authoring`, `audit-authoring`, `memory-notes`: the judgement behind the three things this repo asks you to write. Frontend/motion skills are deliberately not vendored; the README points upstream instead. |
| **7 commands** | `/plan-new` `/plan-gate` `/kb-lint` `/deploy-verify` `/incident` `/regression-sweep` `/code-review` |
| **A knowledge linter** | four silent decay modes (link drift, unreachable notes, schema drift, an index over its per-session token budget) turned into build output. |
| **Templates** | plan (tiered, with the discipline gates as sections), incident, audit, and a commit convention. Plus a router-style `CLAUDE.md`. |
| **Prompt packs** | `general` (code review, deploy verification, post-mortem, regression sweep), `web3` (chain E2E, indexer unit economics, RPC cost, order latency), `security` (application audit, server hardening, dependency drift). |

## What this is not

Not an agent collection, not a prompt megapack, not a wrapper around Claude Code.
The ecosystem has excellent collections; this is deliberately narrow.

## How it fits together

A plan is written from `templates/plan.md` and validated by `plan-gate.sh` before
implementation. It refuses a plan whose premises are asserted rather than read.
While you work, the rules are injected when you touch matching code, and the
blocking hooks catch a broken build or a migration you cannot reverse before the
turn ends. After the deploy, `deploy-verify-run.md` asks for activation proof
rather than a green pipeline. What you learn goes into a note the knowledge
linter can keep honest, and the next session starts with the progress file
already in context.

Nothing here needs the whole system to be useful. The knowledge linter is worth
running on its own; so is the plan gate.

## Case studies

Three incidents, anonymised, with the numbers left in:

1. [A guard that could not fail](EXAMPLES/01-the-vacuous-guard.md). The gate that
   went green on the document introducing the rule it enforced.
2. [A window that inverted a verdict](EXAMPLES/02-the-window-that-inverted-a-verdict.md)
   A 56% improvement that five-minute samples reported as a regression.
3. [The setting that lived in another table](EXAMPLES/03-the-setting-in-another-table.md)
   "13 accounts have no restriction", from a query against one of the two
   tables that hold that setting.

## Two install paths, and why the installer is the primary one

**`rules/` is not a plugin component.** Project rules load from the workspace's
`.claude/rules/`, so a plugin install delivers commands, hooks and skills, and
none of the rules, prompt packs, templates or the knowledge linter. That is not a
packaging oversight; it is what the plugin system supports. The installer
delivers everything, which is why it is the documented path.

| | plugin install | `install/install.sh` |
|---|---|---|
| commands, hooks, skills | yes | yes |
| rules (6 core + pack rules) | **no** | yes |
| prompt packs, templates, docs skeleton, knowledge linter | **no** | yes |

The manifests are validated against the documented schema by `make verify`
(checked against the official reference on 2026-09-08, including that every path
they name exists). What has **not** happened is a real `/plugin marketplace add`
run. That is a user action, and until someone performs it the end-to-end plugin
path is unproven. Recorded here rather than assumed to work.

## Trust model

Installing cairn means shell scripts run automatically in your session: one at
session start, three after every edit, and the edit-time one invokes **your
project's toolchain**, which for Rust means executing that project's `build.rs`.
That is normal for a language server and worth knowing anyway. `.cairn/config.json`
is treated as untrusted input: values that reach a shell are pattern-validated,
and none is ever composed into a command line.

[SECURITY.md](SECURITY.md) has the detail, including the arbitrary-execution bug
this repository's own security prompt found in it, and how to switch the
edit-time hook off when working in repositories you have not read.

## Provenance and safety

Extracted from two private production codebases. No host, credential, threshold,
quota or internal identifier from either is published:
`scripts/sanitize-check.sh` is a CI gate, and it was written and calibrated
**before** any content was moved. A scanner added afterwards does not rewrite
git history. It caught its own first piece of content, which is why the internal
planning document lives outside the repository.

Contributions: see `CONTRIBUTING.md`. The one rule that matters is that a guard
is not accepted without a failing fixture.

MIT licensed.
