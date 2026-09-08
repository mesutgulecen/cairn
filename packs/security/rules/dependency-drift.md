---
description: Suppressions and overrides added to fix a vulnerability become the reason it persists
paths:
  - "**/package.json"
  - "**/go.mod"
  - "**/requirements*.txt"
  - "**/Cargo.toml"
  - "**/*.lock"
  - "**/.*ignore"
---

# Dependency drift

Two mechanisms exist to unblock a dependency problem, and both age into the
problem they solved. Neither announces the transition.

1. **An exclusion written for one dependency silences a class.** A suppression
   added to get past one advisory, written a little too broadly, hides every
   later advisory that matches it. The check keeps reporting clean, which is
   indistinguishable from being clean. Write suppressions with the narrowest
   possible key, an expiry date, and the advisory id in a comment.
2. **A narrow version override pins the vulnerable version in place.** Forcing a
   transitive dependency to a fixed version fixes today's advisory and then
   *prevents* the update that fixes tomorrow's, because the override outranks
   upstream. The commit that solved the problem is the reason it comes back.

Before adding either, ask:

- **What removes this?** An exclusion or override with no removal condition is
  permanent. Write the condition down: "remove when upstream releases > X".
- **How narrow can it be?** Package plus advisory plus version range, never a
  path glob or a whole rule.
- **Who audits it?** Every dependency audit should read the exclusions file as
  carefully as the report, and diff overrides against current upstream. Put that
  step in the prompt, because nobody does it from memory.

Two adjacent traps in the same family:

- **A lockfile that the deploy does not use.** If CI tests with one resolver and
  the deploy installs with another, the dependency set you tested is not the set
  you shipped — and a lockfile audit proves nothing about production.
- **A vendored copy is a fork.** Pinning a commit is right; forgetting that it
  is now yours to patch is not. Record the upstream, the pinned commit and the
  date, and diff on a schedule.
