---
description: Post-deploy verification run (T+30min)
argument-hint: [change] [t30m|t48h|t7d]
---

Apply `docs/prompts/general/deploy-verify-run.md`.

Answer its three questions in order and do not skip ahead: is the new code
running, does the environment carry the configuration, and what single observation
proves the change took effect. A green pipeline is not an answer to the first, and
a populated column is not an answer to the third.
