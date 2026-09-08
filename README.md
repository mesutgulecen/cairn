# cairn

*A cairn is a stack of stones left on a trail so the next traveller does not get
lost. This repository is the same idea for engineering with Claude Code.*

**Status: installable. Everything except the web3 pack and the case studies is
done.** See the roadmap.

## What this is

Most Claude Code repositories distribute **content**: agents, commands, prompt
collections. Cairn distributes **process** — the small number of mechanisms that
decided, in two production codebases, whether an AI-assisted change was correct
or merely plausible:

- **Guards that ship with their calibration.** Every guard here comes with an
  input it must reject and an input it must accept, and `make verify` runs both.
  A guard nobody has watched fail has not been shown to work; it is
  indistinguishable from a guard that always passes.
- **A knowledge base that lints itself.** Notes and docs drift silently: links
  break, notes become unreachable, an index grows past the token budget it
  costs every session. A linter turns those into build output.
- **A plan gate that refuses unproven premises.** A plan that carries a section
  heading is not a plan that carries evidence.
- **Rules written from incidents, not from taste.** Each one opens with the
  measurement that produced it.

## What this is not

Not an agent collection, not a prompt megapack, not a wrapper around Claude
Code. If you want breadth, the ecosystem has excellent collections already. Cairn
is narrow on purpose.

## Install it

```sh
git clone <this repo> && cd cairn
./install/install.sh --target /path/to/your/project          # dry run, writes nothing
./install/install.sh --target /path/to/your/project --apply
```

It never overwrites an existing file, backs up `.claude/settings.json` before
merging into it, and matches hook entries by command so a second run adds
nothing. Then narrow the rules' `paths` globs — the shipped `"**"` is wrong for
your project on purpose.

## What `make verify` proves

```sh
make verify
```

Thirty assertions run, and they are the argument this repository is making.
The plan gate must reject a plan that *describes* the section it is asked to
open, and must accept one whose resolved probe row quotes the marker while
answering it. The migration guard must reject an exemption written without a
reason. The leak scanner must prove that every one of its patterns actually
fires, because two of them once could not match anything at all. The knowledge
linter must find exactly one of each decay mode in a corpus seeded with one of
each — and must NOT fail on a link to a note that has not been written yet. The
shipped plan template must pass the shipped plan gate, because a gate that
rejects its own template is how a process gets abandoned in week two. The
installer's default run must create zero files, and an existing settings.json
must come out the other side with its own keys and its own hooks intact.

Wiring the hooks into a project is described in `plugin/hooks/README.md`.

## Roadmap

| Phase | Contents | Status |
|---|---|---|
| F0 | leak gate + calibration harness + CI | **done** |
| F1 | 6 portable rules | **done** |
| F2 | 5 hooks + calibration fixtures | **done** |
| F3 | knowledge-base linter + note schema | **done** |
| F4 | doc skeleton, templates, 4 general prompts | **done** |
| F4.5 | `web3` sector pack (chain E2E, indexer unit economics, RPC cost) | next |
| F5 | installer (done) + plugin manifest (**unverified**, see below) | **mostly** |
| F6 | anonymised case studies | |
| F7 | launch | |

## Known gap

The plugin manifests (`.claude-plugin/marketplace.json`, `plugin/hooks/hooks.json`)
are written but have **not** been installed through `/plugin marketplace add` and
verified end to end. Until that run happens, use the installer — it is the path
covered by tests. This is recorded here rather than quietly assumed to work,
which is the same standard the rules ask of everything else.

## Provenance

Cairn is extracted from two private production codebases. No configuration,
host, credential, threshold or internal identifier from either one is published:
`scripts/sanitize-check.sh` is a CI gate, and it was written and calibrated
*before* any content was moved, because a scanner added afterwards does not
rewrite git history.

MIT licensed.
