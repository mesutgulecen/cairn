---
description: Token amounts are integers with a per-token scale; the scale is where the money is lost
paths:
  - "**/onchain/**"
  - "**/pricing/**"
  - "**/repository/**"
---

# On-chain numeric precision

Three separate scales meet in every price calculation: the token's decimals, the
database's numeric representation, and the language's float, and each one loses
money differently.

1. **Decimals are per token, and they are not 18.** Reading a balance with a
   hard-coded 18 works for the native token and for most ERC-20s, which is what
   makes the exception expensive: six-decimal stablecoins are the most commonly
   traded assets there are. Fetch decimals from the token, cache them, and treat
   an unknown as fatal rather than defaulting.
2. **A fixed-point numeric is `mantissa × 10^exponent`.** Databases normalise an
   integer by moving its trailing zeros into the exponent, so a supply of exactly
   `1e27` decodes with mantissa `1` while an untidy neighbour decodes with the
   whole value in the mantissa. Reading the mantissa alone is therefore correct
   for untidy numbers and catastrophically wrong for round ones, which is
   precisely why it survives review: it looks intermittent rather than broken.
   In production, every token whose supply was a round power of ten priced at
   roughly zero, and a low-value cleanup rule then deleted 495 of them.
3. **Never round-trip an amount through a float.** A float is fine for a
   displayed price and never fine for a balance, an allowance or a delta. A guard
   comparing two amounts across a float round-trip fires on rounding rather than
   on the condition it was written for.
4. **Price from the pool's own state, and say what the quote is.** A price is
   meaningless without its quote asset. Two pools of the same token quoted in
   different assets are not comparable, and an unrecognised quote must fail
   closed rather than be assumed.
5. **Sanity-check against an independent source before storing.** A pipeline that
   is internally consistent and externally wrong is the normal failure mode, and
   it is cheap to catch: one comparison per token per day is enough to notice
   three orders of magnitude.

**Grep aid:** search touched files for the raw mantissa accessor and for the
literal `18`. A hit is acceptable only if the exponent, or the token's own
decimals, is applied within the next few lines.
