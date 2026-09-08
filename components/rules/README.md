# Rules

Six rules. Each opens with the measurement that produced it, states what makes
the failure invisible, then asks three to six questions to run before writing the
code. They are written to be read at edit time, not memorised.

| Rule | The failure it names |
|---|---|
| `fix-discipline.md` | a fix that breaks what an earlier fix established |
| `measurement-discipline.md` | a number that has not earned the right to drive a decision |
| `unmeasured-is-not-zero.md` | a placeholder zero read as a measurement, so a gate fails OPEN |
| `parallel-paths-parity.md` | two implementations of one decision, changed one at a time |
| `the-second-instance.md` | assumptions baked for instance #1; and a gate that forgets a sibling kind |
| `session-hygiene.md` | sessions that re-derive what the previous one already knew |

## Front matter

Each file carries a `description` and a `paths` list so the harness can inject it
when a matching file is edited, rather than loading everything all the time:

```yaml
---
description: one line, written so a reader can tell whether they need it
paths:
  - "src/workers/**"
  - "src/gates/**"
---
```

**These six rules are 26 KB together.** That is a fixed context cost every time
they all match, and `measurement-discipline.md` alone is a third of it. The
budget is the reason `paths` exists, not tidiness.

The shipped `paths` are `"**"`, deliberately wrong for your project. **Narrow
them on install.** A rule that fires on every edit is a rule that gets skimmed,
and a skimmed rule protects nothing. Point each one at the code where its failure
actually lives.

## Writing your own

Keep the number. A rule that says "measure carefully" is advice; a rule that says
"this was reported as 1.49x from a 25-minute window and was 1.043x over 9.32
hours" changes behaviour, because the reader recognises the situation. Anonymise
whatever you must, but do not round the evidence away.
