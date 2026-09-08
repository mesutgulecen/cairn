# Contributing

One rule matters more than the rest.

## A guard is not accepted without a failing fixture

Every check in this repository must ship with:

1. an input it **must reject** (`fixtures/<guard>/dirty/…`), and
2. an input it **must accept** (`fixtures/<guard>/clean/…`), chosen to be full
   of near misses, and
3. an entry in `scripts/verify.sh` asserting both exit codes.

The reason is not ceremony. The first draft of the plan gate this repository is
built around passed the very document that introduced the rule it was written to
enforce, because it grepped for a phrase and the document merely *described* the
section it demanded. On its first run, the leak scanner here had two patterns
that could not match anything at all — found only by asserting that every
pattern fires on the dirty fixture. A guard that always passes is worse than no
guard: it buys confidence and delivers nothing.

## Writing a rule

Rules live in `plugin/rules/`. A rule opens with the measurement that produced
it — a window, a ratio, a count — then states what makes the failure invisible,
then gives three to five questions to ask before writing the code. Anonymise
freely; keep the number.

## Before you push

```sh
make verify
```

CI runs the same command. If you need to publish a string the scanner flags,
justify it inline with `sanitize-ok: <reason>` — a claim that the match is a
false positive, never permission to publish a real identifier.
