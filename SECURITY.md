# Security

## What installing cairn actually does

Installing wires four hooks into `.claude/settings.json`. From then on, **shell
scripts run automatically in your session**: one when a session starts, three
after every edit. That is the point of them, and it is also the thing to
understand before you install:

| Hook | Runs | Executes |
|---|---|---|
| `session-start.sh` | at session start | `git log`, `ls`, and the knowledge linter (`python3`) |
| `post-edit-lint.sh` | after editing a source file | **your project's toolchain** — see below |
| `migration-guard.sh` | after editing a `*.up.sql` | `python3`, reading two files |
| `env-drift.sh` | after editing a config file | `git diff`, `grep` |

## The one that runs someone else's code

`post-edit-lint.sh` invokes the toolchain of the project you are editing:

- `cargo check` **executes `build.rs`**, which is arbitrary code from that
  repository;
- `npx --no-install tsc` runs a binary from that project's `node_modules`;
- `go build` / `go vet` compile the package, which can invoke a C toolchain
  through cgo.

None of this is exotic — it is what your editor's language server already does —
but it is worth stating plainly: **editing a file in an untrusted repository
runs that repository's build tooling.** If you work in repositories you have not
read, switch it off:

```jsonc
// .cairn/config.json
{ "hooks": { "post_edit": { "enabled": false } } }
```

## `.cairn/config.json` is untrusted input

It lives in the repository. It arrives with a clone, and a pull request can
change it. cairn therefore treats it as untrusted:

- every value that reaches a shell is validated against a pattern, and an
  out-of-pattern value falls back to the default with a warning on stderr;
- **no configuration value is ever composed into a shell command.** The
  knowledge-summary tool is chosen from a fixed set and invoked as an argument
  vector.

This is not hypothetical. An earlier version ran `eval $kb_command` with the
string taken straight from that file — arbitrary command execution, at session
start, with no prompt, from a file that arrives with `git clone`. It was found
by auditing this repository against its own security prompt, demonstrated with a
harmless `touch`, and removed. `scripts/test-install.sh hostile-config` now runs
a malicious config on every `make verify` and asserts that nothing executes and
the session still starts.

## What `sanitize-check.sh` is and is not

It scans for deployment identifiers (hosts, credentials, internal work ids) and
for a set of common secret shapes: AWS, Google, npm, Stripe, JWT, bearer
headers, assigned secrets, private keys, and environment files by name.

**It is not a general-purpose secret scanner.** It has no entropy analysis and no
maintained rule set behind it. For a repository that handles real credentials,
run it alongside a dedicated tool (`gitleaks`, `trufflehog`) rather than instead
of one. Its own coverage is asserted — every pattern must fire on the fixture —
so what it claims to catch, it catches; it makes no claim about the rest.

`--history` scans every text blob in the git history, because a secret deleted
from the working tree is still in the history, and the history is what a clone
hands to a stranger.

## Reporting a vulnerability

Open a GitHub security advisory on the repository, or an issue if the problem is
not exploitable. Please include the version (commit) and a reproduction. There is
no bounty; there is a quick response and credit in the fix commit.

## What cairn never does

- No network calls. Nothing is sent anywhere; every hook is local.
- No telemetry.
- No credential handling of any kind.
- The installer writes only inside `--target`, never overwrites an existing file
  without `--force`, and backs up `.claude/settings.json` to a timestamped name
  before merging.
