# Knowledge layer

A knowledge base decays silently. Nothing throws when a link breaks, when a note
becomes unreachable, when a status says `superseded` and points nowhere, or when
the always-loaded index quietly doubles. The only symptom is a session that fails
to recall something it was told, which reads as a model limitation rather than
as rot.

`knowledge_lint.py` turns all four into build output.

```sh
knowledge_lint.py                 # report
knowledge_lint.py --check         # exit 1 on a finding (hook / CI)
knowledge_lint.py --apply         # rewrite the links it can repair
knowledge_lint.py --index notes/ --corpus docs/ --entry notes/MEMORY.md
```

By default it looks for notes where the harness keeps them
(`~/.claude/projects/<project-slug>/memory`) and lints them together with the
project's `docs/`. Override with `--index`, `--corpus`, `--entry`, `--root` and
`CAIRN_MEMORY_DIR`.

## Why this cannot be a CI job

The notes usually live under `$HOME`, outside the repository, so a CI runner sees
almost none of the graph. Run it from a `SessionStart` hook instead. The shipped
`session-start.sh` prints its summary block, and let CI check only the parts
that are committed.

## The four findings

| Finding | Why it is invisible | Fails `--check` |
|---|---|---|
| link drift (`[[a-note]]` vs `a_note.md`) | resolves for a human, not for a traversal | yes |
| unreachable note | tokens spent writing, zero recall | yes |
| schema drift | a superseded note still reads as live | yes |
| index over budget | a per-session cost nobody is billed for visibly | yes |
| dangling link | forward links are the convention, not an error | **no** |

The last row is the one to keep: making it fail would push people to stop writing
`[[links]]` to notes they have not written yet, which is the mechanism that makes
the graph grow at all.

The schema is `note-schema.md`; `MEMORY.md.tmpl` is a starting index.
