---
description: Assumptions baked for instance #1 break on instance #2, and a gate branching on one variant forgets its sibling
paths:
  - "**"   # narrow to dispatch, routing, per-variant gates and anything storing per-variant config
---

# The second instance

The most expensive class of change in a young system is adding the **second** of
something the code has only ever had one of: the second chain, the second tenant,
the second region, the second currency, the second payment provider, the second
deployment target.

Nothing announces it. The first instance's identity was never a variable, so it
was written into constants, into default branches, into queries that did not need
a filter yet, and into payloads that did not need to say which instance they
belonged to. Every one of those is correct until the day it is silently wrong.

In one codebase, adding a second instance of one concept produced **32 separate
leak fixes** in a single month.

## Before editing dispatching code, ask

1. **Unscoped selector?** Does a query, repository method or worklist select rows
   **without filtering by instance**, so a row belonging to the new instance gets
   processed against the old one's connection, constants or endpoint? Reconciliation
   jobs, monitors and cleanup workers were all this. They were written when a
   filter would have been a no-op.
2. **Constant leak?** Is a package-level constant belonging to instance #1
   compared by value instead of resolved per instance? One pricing function
   matched the first instance's reference asset by address, and priced the second
   instance's pools roughly **1,780× wrong** while marking the result valid.
3. **Does the default branch fall through to instance #1?** A `switch` whose
   unknown case lands on the original path fails OPEN into the wrong instance.
   For anything consequential, prefer fail-closed: skip and alert.
4. **Per-instance enablement missing?** New enrichment, tagging or caching often
   needs an explicit "enabled for instance #2" alongside the one it already has.
   Without it the new instance silently receives empty data, and a downstream gate
   starves rather than erroring.
5. **Does the payload say which instance it belongs to?** Any message, event or
   API response carrying an identifier that is **byte-identical across instances**
   must also carry the instance. Otherwise the consumer infers it, and infers the
   original. This bit one system twice: a feed, then the entire notification layer,
   producing links that pointed confidently at the wrong system.
6. **Is an unrecognised value priced as the familiar one?** A new category
   defaulting to the known one is worse than an error: it produces plausible
   output marked valid. An unrecognised input must fail closed.

## The forgotten sibling

The same split appears one level up, in code that branches per **kind** rather
than per instance. A gate written for the original kind gets a carve-out for a
new kind, and the *sibling* kind, added later and sharing the same need, is
forgotten. Every new `if kind == A` is a prompt to ask whether kind B needs it.

Three failure shapes worth knowing:

- **Exempt from counting is not exempt from the contract.** A union like "true
  only if every participant rejects it" must not skip an exempt participant *and*
  still accept its result unjudged. That inverts the contract, and it can starve
  the exempt participant's own pipeline.
- **Never mutate shared config to force a decision.** Flipping a flag on the
  shared configuration object to make one case work leaks into every other case.
  Branch on a local, leave the persisted config alone.
- **A null kind is the legacy kind.** Treat an absent discriminator as the
  original default; do not let it fall into a carve-out branch.

## It reaches the UI, and the save path, and the empty value

A rendering path is a read. Three separate components each parsed the *same wrong
field* to display a per-account setting, because for one kind that field holds
something else entirely. The correct reader already existed and the editor used
it, which is why the editor showed the right values next to a card showing the
wrong ones. Fix it in **one** component: three copies is how one wrong expression
reached three screens.

Then ask what an **empty** value means, and note there are three answers, not
two:

- *none selected* for one kind, *everything, including options added later* for
  another. The semantics can invert between siblings even when the column names
  match.
- **present but no longer meaningful.** A reader that returned the full default
  set when none of the stored values survived the current options drew an account
  pinned to a retired option as *unrestricted*; the backend read the same row as
  an allow-list nothing matches, so it did nothing at all. Two surfaces, opposite
  readings, one column. When you write `kept.length > 0 ? kept : fallback` over
  persisted configuration, **that ternary is the bug**: it converts "we cannot
  honour this" into "there was nothing to honour". Return the third state and
  name it.

**A save path is a read too, and it inverts the same way.** A "pick at least one"
guard tested the serialized shape, which for one kind is always non-empty
whatever the user ticked, so the guard could never fire there, and clearing every
box silently flipped the account from "matches nothing" to "matches everything".
Guard the **selection**, never the serialized shape: the wire format is exactly
where the per-kind asymmetry lives.
