---
name: memory-notes
description: Write a durable memory note that a future session will actually recall — one fact per file, front matter recall can judge, absolute dates, and an index line. Use when asked to remember something, after learning a non-obvious fact, or when the knowledge linter reports schema or reachability findings.
---

# Writing a memory note

A note that is never recalled cost tokens and returned nothing. Recall reads the
`description` first and the body only if that line earns it, so the description
is the note.

## Shape

One fact per file, named `<type>_<slug>.md`:

```markdown
---
name: <short-kebab-case-slug>
description: <one line; recall judges relevance from this alone>
metadata:
  type: user | feedback | project | reference
---

<The fact. For feedback and project, add **Why:** and **How to apply:** lines.
Link related notes with [[their-name]].>
```

Types: `user` (who the person is), `feedback` (how to work, with the why),
`project` (ongoing work and constraints), `reference` (a durable fact or trap).

## Four rules that decide whether it survives

1. **Absolute dates, always.** "Last Tuesday" is worthless in three months, and a
   note that silently expires is worse than no note.
2. **Keep the number.** "The build is slow" is an opinion; "p50 8m52s over 12
   cold runs, range 8m10s–11m04s" is a fact a future session can act on and
   compare against.
3. **Do not store what the repository already records.** Code structure, past
   fixes, git history, project guidelines — all cheaper to read than to remember,
   and they go stale without any signal. If asked to remember one of those, ask
   what was *non-obvious* about it and store that instead.
4. **Do not store what only matters to this conversation.**

## Link liberally, including to notes that do not exist

`[[a-note-not-written-yet]]` is not an error — it marks something worth writing.
The linter reports dangling links without failing on them, precisely so this
stays cheap. What it *does* fail on is a link that only resolves after
normalisation (`[[a-note]]` against `a_note.md`): that is drift, and drift
compounds.

## Add the index line, and respect its budget

One line per note in the index, never note content:

```markdown
- [Title](file.md) — the hook that makes a future session open it
```

The index is loaded into **every** session, so its size is a fixed per-session
cost. Over budget, move the oldest lines into a dated archive note that stays
reachable by a link — reachability is measured by traversal, so an archived note
is still indexed.

## When superseding

Set `status: superseded` and `superseded_by: <name>` on the old note rather than
deleting it. A superseded note that still reads as live is a wrong answer waiting
to be recalled; a deleted one takes its history with it.

Schema: `knowledge/note-schema.md`. Check with `knowledge/knowledge_lint.py`.
