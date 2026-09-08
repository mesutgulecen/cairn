# General prompt pack

Four repeatable audits that assume nothing about your domain. Each is a task
definition you hand to an agent — by path, or through a slash command that points
at it.

| Prompt | Run it when |
|---|---|
| `code-review.md` | before a release; after a large refactor |
| `deploy-verify-run.md` | T+30min after every deploy or flag flip |
| `incident-postmortem-run.md` | a production symptom exists (never on a hunch) |
| `regression-class-sweep.md` | a bug pattern is identified — always on its second occurrence |

## Conventions every prompt follows

Written from what went wrong when they did not.

1. **No assumptions.** Every finding carries evidence: a query result, a log line,
   a command output, a `file:line`. Anything else is `UNVERIFIED` or
   `INSTRUMENTATION GAP`, and stays in the report under that label.
2. **Previous output is never overwritten.** Reports are dated; finding ids
   continue from the last run and are never reused or renumbered.
3. **Run state does not live in the prompt body.** Anything that evolves — a
   quarantine list, a flag's current value, which fixes have landed — goes in a
   separate ledger file or in the dated report. A dated "current state" line
   inside a prompt is a lie with a long half-life.
4. **Ask the user only at decision points.** Scope, a destructive action, a choice
   between fixes. Not to share information. A destructive action needs explicit
   authorisation, and approval for one is not approval for the next.
5. **Schema facts are re-verified at run time.** Table and column names inside a
   prompt carry a "last verified" date and are checked by introspection at the
   start of a run, not trusted.
6. **Arguments are declared in a table at the top**, with defaults.
7. **One canonical output path**, dated: `docs/audits/<YYYY-MM-DD>/<name>-<date>.md`.

## Writing your own

The strongest prompts here are the ones that say what does **not** count as
evidence — a populated column is not activation proof, a mean is not the
expensive case, a fit does not locate a cost. State the disqualifier, not just
the goal: the goal is obvious, and the disqualifier is what a careful reader
would otherwise get wrong.
