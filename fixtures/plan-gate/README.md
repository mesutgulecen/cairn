# Calibration fixtures for `components/hooks/plan-gate.sh`

Four documents the gate MUST reject and two it MUST accept. `scripts/verify.sh`
asserts the exit code *and the reason*: a guard that rejects the right document
for the wrong reason is one refactor away from rejecting nothing.

The two accepted documents are the important half. Each pins a false positive
that a real draft of this gate produced:

- `01-complete.md` carries a resolved probe row that quotes the marker while
  reporting its answer, and hex literals that a naive multiplier check reads as
  `0x…` speedups. An earlier gate rejected both.
- `02-lower-tier.md` is below the gated tier and must pass untouched. A process
  that argues with small changes is a process people route around.
