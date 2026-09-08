---
description: Lint the knowledge base: link drift, orphans, schema, index budget
argument-hint: [--apply]
---

Run `knowledge/knowledge_lint.py $ARGUMENTS` and summarise: counts first, then
anything that fails the check.

Dangling links are reported but are **not** failures. A link to a note that does
not exist yet is how this convention marks work worth doing. Do not "fix" them by
deleting the link.

If the index is over budget, the repair is to move the oldest lines into a dated
archive note that stays reachable by a link, not to delete them.
