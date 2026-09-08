# Calibration fixtures for `knowledge/knowledge_lint.py`

Three miniature knowledge bases:

- `clean/` — everything resolves; must produce zero findings.
- `drifted/` — carries **exactly one** of each failure: a kebab-case link that
  only resolves after normalisation, a note missing its `description`, a note
  reachable from nowhere, and (run with `--index-budget 200`) an oversized index.
  One each, so a detector that stops working shows up as a changed count rather
  than as a vague "still fails".
- `forward-link/` — a dangling link and nothing else. It must **pass**: writing
  `[[a-note]]` before the note exists is how the convention marks work worth
  doing, and failing on it would stop people linking at all.
