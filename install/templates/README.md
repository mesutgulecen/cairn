# install/templates

What the installer copies into a project: the `docs/` skeleton, the document
templates, and a `CLAUDE.md` starting point.

Nothing here is machinery — it is shape. The shape matters because the guards
depend on it: `plan-gate.sh` looks for the sections `templates/plan.md` provides,
and `session-start.sh` looks for the progress file `docs/README.md` describes. A
project that keeps the guards but drops the shape gets a gate that rejects every
plan it is given.

`make verify` asserts that the shipped plan template passes the shipped plan
gate, so the two cannot drift apart unnoticed.
