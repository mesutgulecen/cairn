---
description: Review the current changes for correctness and the known failure classes
argument-hint: [scope] [focus]
---

Apply `docs/prompts/general/code-review.md` with: $ARGUMENTS

Read the project guide and the path-scoped rules first — most "bugs" in an
unfamiliar codebase are conventions you have not read yet. Read the diff twice:
once for what it does, once for what it stops doing. Findings only, ranked by
consequence.
