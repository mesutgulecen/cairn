# Prompt — server and infrastructure hardening audit

| Argument | Default | Meaning |
|---|---|---|
| `hosts` | all | which hosts to audit |
| `baseline` | `docs/runbooks/hardening.md` | the intended state |
| `output` | `docs/audits/<date>/server-hardening-<date>.md` | report path |

Read-only. Every check compares the **running** state against the baseline
document; where they differ, the finding names which one is wrong — drift is as
often a stale document as a misconfigured host.

## Checklist

**Exposure.** What listens, on which interface, reachable from where. Compare the
firewall's rules against the listening sockets: a service bound to all interfaces
behind a firewall rule is one rule change from public, and the rule change will
be made by someone who does not know that.

**Access.** Key-based SSH only, root login disabled, per-person keys rather than
a shared one. Enumerate authorised keys and name an owner for each; a key nobody
can name is a finding, not a mystery.

**Services.** Each unit's user, its restart policy, its resource limits, and
whether it runs with more privilege than it needs. A service that restarts
forever on a config error looks healthy in a process list.

**Updates.** Unattended security updates on or deliberately off, with the reason
recorded. Kernel and library versions against known advisories.

**Backups.** Not "is a backup configured" but **"when was a restore last
performed"**. An untested backup is a belief. Check retention against the
retention *policy*, and check that the policy's window exceeds the longest
plausible detection delay — a backup chain shorter than the time it takes to
notice corruption restores the corruption.

**Observability.** Log retention in hours, not adjectives. Know the number: many
default journal configurations keep hours, which means an incident investigated
the next morning has no logs. Database counters usually outlive logs by an order
of magnitude — know which of your evidence sources dies first.

**Automation traps.** Two that recur:

- A threshold expressed as a **percentage** silently changes meaning when the
  disk is resized. Alert on absolute free space, or re-derive on resize.
- A retention job that reads access time is disarmed by anything that touches
  files — including the audit that checks them. Read modification time.

## Output

A table of host × check × `pass` / `drift` / `fail`, then findings. For every
drift, state whether the host or the baseline document is wrong, and fix the
document in the same session — a baseline nobody trusts is not a baseline.
