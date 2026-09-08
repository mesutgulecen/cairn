---
description: A placeholder zero read as a measurement makes a safety gate fail OPEN
paths:
  - "**"   # narrow to metric extraction, gate predicates and serialisation
---

# Unmeasured is not zero

The most-repeated production bug of one month, in one codebase, was a single
shape: a producer writes a synthetic **0** for something it never measured: the
window had no events, the pointer was nil, the probe had not run, and a
downstream `value <= threshold` safety check then **fails OPEN** on that fake
zero as if it were a real reading.

It survives review because the code is unremarkable. `0` is a plausible number.
The gate looks conservative. Nothing is null, nothing throws, and the ledger
records a decision that was never actually informed.

Before touching metric extraction, gate predicates or audit serialisation:

1. **Producer: is this 0 a measurement or a placeholder?** If nothing was
   observed, write **NULL / NaN**, not 0. Gate the write on an explicit
   `measured` flag rather than on the value being present.
2. **Consumer: does the reader turn NULL back into a sentinel?** A gate must read
   unmeasured as NaN, never as 0. `NaN <= x` and `x < NaN <= y` are both **false**,
   so the gate fails CLOSED, which is the correct direction for a check that
   cannot see its input.
3. **Key on measured-ness, never on `value == 0`.** A three-state design
   (`value` + `probed`) distinguishes "checked and false" from "never checked". A
   `NOT NULL DEFAULT FALSE` boolean has no such distinction; if the gate must tell
   them apart, add a `checked_at` timestamp.
4. **Not every zero is a sentinel.** Volume, counts and absolute totals may
   legitimately treat missing as zero. Scope this rule to the *safety* family:
   ratios, thresholds, quorum counters, and leave the rest alone. A blanket ban
   produces a wall of noise, and a noisy rule is an ignored rule.
5. **One NaN destroys a whole audit record.** JSON encoders fail **atomically** on
   a non-finite float: a single fail-closed NaN blinds the entire forensic row
   that would have explained the decision. Sanitise non-finite values at the
   serialisation boundary. Note the chain: fixing rule 2 produces *more* NaNs
   and therefore widens this surface; the two changes land together.
6. **Fix it on every parallel path.** If a second implementation mirrors the
   first (see `parallel-paths-parity`), a sentinel fixed on one side is a drift
   bug on the other.

## The decimal variant: a number is not its mantissa

A fixed-point numeric is `mantissa × 10^exponent`, and databases normalise an
integer by **moving its trailing zeros into the exponent**. So `1e27` decodes as
mantissa `1`, exponent `27`, while an untidy neighbour decodes with the whole
value in the mantissa and an exponent of zero.

Reading the mantissa alone is therefore *correct for untidy numbers and
catastrophically wrong for round ones*, which is exactly why it survives review:
it looks intermittent rather than broken. In production every token whose supply
was exactly `1e27` priced at roughly zero, and a low-value cleanup rule then
deleted 495 of them.

Use a decoder that applies the exponent. Never assign a raw mantissa into a
big-integer field: by the time any later reader sees it, the exponent is gone and
the damage is unrecoverable.

**Grep aid:** search the files you touched for the raw mantissa accessor. A hit is
acceptable only if the exponent is applied within the next few lines.
