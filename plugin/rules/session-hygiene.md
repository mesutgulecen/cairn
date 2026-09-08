---
description: Keep the session cheap and resumable — where output goes, what gets delegated, what gets written down
paths:
  - "**"
---

# Session hygiene

These are process rules, not code rules. They exist because the most expensive
pattern in AI-assisted work is not a wrong answer — it is a root-cause hunt that
takes five sessions, each one re-deriving what the last already knew.

1. **Bulk output goes to a file, not into the conversation.** Log dumps, query
   results and wide file sweeps land in a scratch file and are read back with
   `grep`. Raw dumps are the single largest avoidable context cost, and the tail
   of one is usually what pushes the useful part out of reach.
2. **Make your own output greppable.** When you add a log line, give it a stable
   snake_case event tag and `key=value` fields. You are writing it for the
   `grep` you will run at 2am, not for a human reading sequentially.
3. **Delegate verbose reads to a cheaper model.** Large scans return a *summary*
   — a median and a count — to the main session, never a wall of rows. Report
   medians and counts; an average over a heavy tail describes nothing (see
   `measurement-discipline` §3).
4. **Keep a progress file for the active phase, and surface it on session start.**
   Four headings are enough: what is done (with the commit and one line of
   evidence), what is next (and why), what is blocked (and by what). A
   `SessionStart` hook that prints the last commits plus this file's head turns a
   cold start into a resumption.
5. **Separate structural from behavioural commits.** A rename, an extraction or a
   move goes in its own commit so that review can read the behaviour diff clean.
   This is the single cheapest thing you can do for the reviewer, and the reviewer
   is often you, later, without the context.
6. **One worktree per concurrent session.** If two sessions may touch the
   repository at once, give each its own `git worktree`. Otherwise one session's
   uncommitted edits get swept into the other's commit — which has happened, and
   is nearly invisible in review. Until then, `git diff --stat HEAD` before every
   commit.
