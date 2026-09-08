# Note schema

One fact per file. The file name is the address, the front matter is what recall
reads first, and the body is what gets loaded once recall decides it is relevant.

```markdown
---
name: <short-kebab-case-slug>
description: <one line; recall judges relevance from this alone>
metadata:
  type: user | feedback | project | reference
  status: pending | open | resolved | superseded   # optional; absent means live
  superseded_by: <name of the note that replaced this one>   # required if superseded
---

<The fact. For `feedback` and `project`, follow it with **Why:** and
**How to apply:** lines. Link related notes with [[their-name]].>
```

## The four types

| Type | Holds |
|---|---|
| `user` | who the person is: role, expertise, standing preferences |
| `feedback` | how you should work: corrections and confirmed approaches, **with the why** |
| `project` | ongoing work, goals, constraints not derivable from the code or git history |
| `reference` | a durable fact or pointer: a measured number, an external resource, a trap |

Convert relative dates to absolute ones. "Last Tuesday" is worthless in three
months; a note that silently expires is worse than no note.

## Linking

Link liberally with `[[name]]`. A link to a note that does not exist yet is
**not an error**. It marks something worth writing. That is why the linter
reports dangling links but does not fail on them, while it does fail on a link
that resolves only after normalisation: those are drift, and drift compounds.

## Two rules that decide what NOT to write

1. **Do not store what the repository already records.** Code structure, past
   fixes, git history and the project's own guidelines are cheaper to read than
   to remember, and a memory of them goes stale without any signal.
2. **Do not store what only matters to this conversation.** If asked to remember
   something in either category, ask what was non-obvious about it and store
   that instead.

## The index is a fixed cost

The index file (`MEMORY.md`) is loaded into **every** session, so its byte count
is a per-session tax. The default budget is 20,000 bytes, roughly 5K tokens. Over
budget, the oldest lines move into a dated archive hub that stays reachable by a
link. The linter measures reachability by traversal, so an archived note is
still "indexed", just not resident.

One line per note in the index, never note content:

```markdown
- [Title](file.md), the hook that makes a future session open it
```

## What the linter enforces

`knowledge_lint.py` fails (`--check`) on: a link that resolves only after
normalisation, a schema violation, a note unreachable from the index, and an
index over budget. It reports, but does not fail on, dangling links and
ambiguous names.
