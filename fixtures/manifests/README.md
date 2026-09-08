# Calibration fixtures for `scripts/check-manifests.py`

Two manifests that must be rejected:

- `invalid-marketplace/` — no `owner` (required), and a `source` pointing at a
  directory that does not exist. The second is the realistic failure: a manifest
  stays valid JSON while quietly naming a path that was renamed.
- `invalid-plugin/` — declares a `hooks` path that is not there, and has none of
  the documented component directories, so it would install as an empty plugin.

The valid pair is the repository's own, checked by the same run.
