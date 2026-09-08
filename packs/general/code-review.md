# Prompt — codebase review

| Argument | Default | Meaning |
|---|---|---|
| `scope` | changed files on this branch | what to read |
| `depth` | `normal` | `normal` \| `deep` (deep traces call paths) |
| `focus` | all | `correctness` \| `concurrency` \| `data` \| `performance` |
| `output` | `docs/audits/<date>/code-review-<date>.md` | report path |

## Rules

1. **Every finding carries evidence** — a `file:line`, a query result or a
   reproduction. A finding you cannot point at is labelled `UNVERIFIED` and kept.
2. **Do not renumber.** Continue finding ids from the previous review.
3. **Rank by consequence, not by count.** Ten style notes above one data-loss bug
   is a report nobody finishes reading.

## Method

**1 — Orient.** Read the project guide and the path-scoped rules first. Most
"bugs" in an unfamiliar codebase are conventions you have not read yet; check the
comment before calling something drift.

**2 — Read the diff twice.** Once for what it does, once for what it *stops
doing*. A removed check, a widened predicate, a loosened type and a deleted
default are the changes that pass review most easily.

**3 — Ask the class questions.** For each change:

- *Second instance* — does this bake in an assumption that holds for exactly one
  chain, tenant, region, currency or provider?
- *Forgotten sibling* — does a branch on one variant need the same treatment for
  its sibling?
- *Parallel path* — does this decision exist twice (simulation/live,
  preview/apply, read/write model)? Did both sides move?
- *Unmeasured zero* — can a placeholder 0 or NULL reach a threshold and make it
  fail OPEN?
- *Prior fix* — does this change a constant, exemption or predicate an earlier
  fix added? Read that commit before judging it arbitrary.
- *Detached work* — does a background task have a failure path, or does it
  vanish silently?

**4 — Verify the top findings adversarially.** For each, try to prove it is
*wrong*: find the guard you missed, the caller that never passes that value, the
test that already covers it. Report what survives, and say what you checked.

**5 — Write the report** using `templates/audit.md`.

## Output discipline

Findings only. A review that lists what is fine is a review whose findings are
buried.
