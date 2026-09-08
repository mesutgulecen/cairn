# 3. The setting that lived in another table

## What happened

The question was simple: can any of our accounts buy from this source, or is
something filtering it out?

One query, one table, thirteen rows, every one of them empty. The answer given
was **"no account has a restriction"**.

There are two kinds of account in that system, and the second kind stores the
same setting in a **different table**, under a different name. Two of the
thirteen had explicit lists. One of them will never pick up a source added after
its filter was last saved.

The contradicting row had been printed in the same session, hours earlier, and
quoted in a report. It was not missing information. The narrow question stopped
it being connected.

## Why it was invisible

The sentence that carried the conclusion was **"13 accounts have no
restriction"**. That sentence is about behaviour. The query was about a column.
The gap between them is exactly where the second table lives, and the sentence
gives the reader nothing to pull on. It reads as settled.

Had the sentence been **"13 accounts have an empty `accounts.sources`"**, the
next question asks itself: *is that the only place this setting lives?*

## The same split, in the UI

The identical asymmetry produced a display bug on three screens at once. Three
components each parsed the same field to draw an account's configured sources.
For one kind of account that field holds something else entirely, so all three
drew the wrong thing, while the *editor*, which used the correct reader, showed
the right values. A user could see the correct configuration in the editor and
the wrong one on the card, in the same session.

And the empty value turned out to have three meanings, not two: *none*, *all
including ones added later*, and, the one nobody had modelled, *present but no
longer meaningful*. A reader that fell back to "everything" when none of the
stored values survived the current options drew an account pinned to a retired
option as unrestricted, while the backend treated the same row as an allow-list
that matched nothing. Two surfaces, opposite readings, one column.

## What stops it now

`components/rules/the-second-instance.md` carries both halves: the variant split in
code, and the same split in queries and rendering paths. Three habits from it:

1. **Enumerate the kinds first.** Different kinds store the "same" setting in
   different places *on purpose*; that is the carve-out, in schema form.
2. **Grep the concept, not the column.** A second table holding the same idea
   under another name is the ordinary case, not the exception.
3. **Name the column in the sentence.** The cheapest guard there is, and it
   protects the writer as much as the reader.

`packs/general/code-review.md` asks the sibling question on every change, and the
rule adds the third-state warning: `kept.length > 0 ? kept : fallback` over
persisted configuration converts "we cannot honour this" into "there was nothing
to honour". That ternary is the bug.
