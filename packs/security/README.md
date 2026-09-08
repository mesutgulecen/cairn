# Security pack

Two audits and one rule. Opt in: `install/install.sh --packs general,security --apply`.

| Item | What it covers |
|---|---|
| `app-security-audit.md` | surface map, authn/authz, injection sinks, secrets, dependencies, limits |
| `server-hardening-audit.md` | exposure, access, services, updates, backups, observability |
| `rules/dependency-drift.md` | suppressions and overrides that become the vulnerability |

Both audits are **delta runs**: read the previous report and check whether its
findings are still live before hunting new ones. A report that re-finds what was
already fixed trains its readers to skim, and a skimmed security report is worse
than none.

Two positions worth stating up front, because they are what most checklists get
wrong:

- **"Is a backup configured" is not the question.** "When was a restore last
  performed" is. An untested backup is a belief, and the retention window has to
  exceed the time it takes to *notice* corruption. Otherwise a restore restores
  the corruption.
- **A drift finding names which side is wrong.** When the running state differs
  from the baseline document, it is as often a stale document as a misconfigured
  host. Fix whichever is wrong in the same session; a baseline nobody trusts has
  already stopped being a control.

No exploitation without explicit written authorisation, and never against a
system you do not own. The `exploit` mode exists for authorised testing of your
own infrastructure and is off by default.
