# Fix commit convention

A fix commit answers three questions that a diff cannot: what was broken, how it
was found, and what stops it coming back.

```
fix(<area>): <what is now true, not what you did>

<Why it was wrong. The mechanism, not the symptom. The reader can see the
symptom in the issue. Name the specific line, query or value.>

<What made it invisible: why review, tests and monitoring all passed.>

detected-by: <alert | audit <name> | user report | regression test | chance>
```

Three habits behind it:

1. **The subject says what is now true.** "retry no longer double-charges on a
   timeout" survives a rename; "fix retry bug" does not.
2. **`detected-by:` is a trailer you can query.** After a quarter, counting them
   tells you whether your alerts or your luck are finding your bugs. `chance` is
   an honest and very informative value.
3. **Structural and behavioural changes are separate commits.** A rename bundled
   with a logic change forces the reviewer to diff two things at once, and they
   will read the easier one.

For a money-path fix, the regression test is written first, fails on the unfixed
code, and is named after the incident so a future reader can find every test
guarding this class with one grep.
