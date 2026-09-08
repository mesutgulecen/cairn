# Incident: <one-line symptom> (<YYYY-MM-DD>)

**Severity:** <money | data | availability | cosmetic> · **Detected by:** <alert |
user report | audit | chance> · **Duration:** <first bad event> → <resolved>

Every field below is mandatory and evidence-based. "Probably" is not a finding.
If something is unknown, write `UNVERIFIED` and say what read would settle it.
an honest gap is useful; a confident guess is not.

## Symptom

What was observed, by whom, with the raw evidence (a log line, a row, a
screenshot path). Not the cause.

## Impact

Quantified: rows, users, money, duration. If the blast radius is unknown, say so
and give the query that would size it.

## Timeline

| Time (UTC) | Event | Evidence |
|---|---|---|
| | first bad event (not first *noticed* event) | |
| | detection | |
| | mitigation | |
| | resolution | |

The gap between the first bad event and detection is usually the most useful
number in the whole document. It measures your instrumentation, not your luck.

## Root cause

The mechanism, at the level of a specific line, query or configuration value. Not
"a race condition" is a category. *Which* two operations, in what order, on what state.

## Why it was invisible

What made this survive review, tests and monitoring. This section is the one that
generates the durable fix; treat it as the point of the document.

## Detection gap

What would have caught it sooner, and whether that is worth building. An alert
that would have fired on this and nothing else is a good candidate; one that
would fire on everything is not.

## Fix

- **Immediate:** <what stopped the bleeding>
- **Durable:** <the mechanism that closes the class, not the instance>
- **Regression test:** <name it after this incident so a future reader can grep it>

For anything on the money path, the regression test is written **before** the fix
and must fail on the unfixed code. A test written afterwards asserts your
understanding of the fix, not the behaviour of the bug.

## Same-pattern sweep

Where else does this pattern exist? List what you searched for and what you found
including "searched X, found none", which is a result.

## Follow-ups

| # | Item | Owner | Why it is not done now |
|---|---|---|---|
