#!/usr/bin/env python3
"""Lint an agent knowledge base: memory notes plus a docs wikilink graph.

Four silent failure modes, none of which ever raises an error on its own:

1. LINK DRIFT — notes are stored as `feedback_no_assumptions.md` (snake,
   type-prefixed) while links get written as `[[feedback-no-assumptions]]` or
   `[[no-assumptions]]`. The edge is broken; nothing complains. (95 found and
   repaired 2026-08-10.)

2. UNREACHABLE NOTES — a note nobody links to and MEMORY.md does not index is
   invisible to any future session: tokens spent writing, zero recall. Measured
   as a BFS from MEMORY.md over wikilinks, markdown links and `superseded_by`,
   so a note reachable only via an archive hub still counts. (103 of 442 on
   2026-08-10, ~79K tokens.)

3. SCHEMA DRIFT — `metadata.type` outside its block, an unknown `status`, or a
   `status: superseded` whose `superseded_by` points nowhere. A superseded note
   that still reads as live is a wrong answer waiting to be recalled.

4. INDEX BUDGET — MEMORY.md is loaded into *every* session, so its byte count is
   a fixed per-session token cost. Over budget, the oldest lines belong in a
   dated `archive_<month>_<year>.md` hub.

Schema and the status vocabulary: knowledge/note-schema.md.

Nothing here raises on its own, which is the point: a knowledge base decays
silently, and the only symptom is a session that fails to recall something it
was told.

Usage:
    knowledge_lint.py                      # dry-run report
    knowledge_lint.py --apply              # repair fixable links in place
    knowledge_lint.py --check              # exit 1 on any finding (hooks/CI)
    knowledge_lint.py --quiet              # summary block only
    knowledge_lint.py --index notes/ --corpus docs/ --entry notes/MEMORY.md

A DANGLING link is reported but does NOT fail --check: writing `[[a-note]]`
before the note exists is how the convention marks something worth writing.
Fixable links, schema violations, orphans and an over-budget index do fail.
"""

from __future__ import annotations

import argparse
import collections
import os
import re
import subprocess
import sys
from pathlib import Path

# Type prefixes the memory convention uses; a link may legitimately omit them.
TYPE_PREFIXES = ("feedback", "reference", "project", "user", "todo", "archive", "dev")
VALID_TYPES = {"user", "feedback", "project", "reference"}
# Vocabulary is observed, not invented: `open` and `resolved` were already in
# use, and MEMORY.md drew the same distinctions with emoji. Absent == live.
VALID_STATUS = {"pending", "open", "resolved", "superseded"}
MEMORY_INDEX_BUDGET = 20_000  # bytes; ~5K tokens loaded every single session

FENCE_RE = re.compile(r"^\s*(```|~~~)")
INLINE_CODE_RE = re.compile(r"`[^`]*`")
WIKILINK_RE = re.compile(r"\[\[([^\[\]]+)\]\]")
MDLINK_RE = re.compile(r"\[[^\]]*\]\(([^)\s]+\.md)\)")
POSIX_CLASS_RE = re.compile(r"^:[a-z]+:$")


def normalize(name: str) -> str:
    """kebab -> snake, lowercased, trailing .md dropped."""
    if name.endswith(".md"):
        name = name[:-3]
    return name.lower().replace("-", "_")


def repo_root(explicit: str | None = None) -> Path:
    """The project being linted — not where this script happens to live.

    An installed copy sits inside the project it lints, but a shared checkout
    does not, and resolving the root from __file__ silently lints the wrong
    repository in that case.
    """
    if explicit:
        return Path(explicit).resolve()
    try:
        out = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            capture_output=True, text=True, check=True,
        )
        return Path(out.stdout.strip())
    except Exception:
        return Path.cwd()


def memory_dir(root: Path) -> Path:
    """Claude Code keys per-project memory by a slug of the absolute repo path."""
    if override := os.environ.get("CAIRN_MEMORY_DIR"):
        return Path(override)
    return Path.home() / ".claude" / "projects" / str(root).replace("/", "-") / "memory"


def frontmatter(path: Path) -> dict[str, str]:
    """Flat view of the frontmatter; `metadata:` children are prefixed `metadata.`.

    Deliberately a 20-line subset parser rather than a PyYAML dependency — the
    corpus only ever uses scalar keys and one nested block, and this script must
    run from a git hook on a machine with nothing installed.
    """
    text = path.read_text(encoding="utf-8", errors="replace")
    if not text.startswith("---\n"):
        return {}
    end = text.find("\n---\n", 4)
    if end == -1:
        return {}
    out: dict[str, str] = {}
    in_meta = False
    for line in text[4:end].split("\n"):
        if not line.strip():
            continue
        indented = line.startswith((" ", "\t"))
        if not indented:
            in_meta = line.startswith("metadata:")
        if ":" not in line:
            continue
        key, _, val = line.partition(":")
        key, val = key.strip(), val.strip().strip("\"'")
        if indented and in_meta:
            out[f"metadata.{key}"] = val
        elif not indented:
            out[key] = val
    return out


def iter_links(path: Path):
    """Yield (lineno, target) for wikilinks outside code fences and code spans.

    `TopicSets=[[SwapV4Topic],[poolIds]]` in a Go snippet is not a wikilink, and
    neither is anything inside a ``` block — both are excluded here rather than
    filtered downstream, so the counts in the report are honest.
    """
    in_fence = False
    text = path.read_text(encoding="utf-8", errors="replace")
    for lineno, line in enumerate(text.splitlines(), 1):
        if FENCE_RE.match(line):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        for raw in WIKILINK_RE.findall(INLINE_CODE_RE.sub("", line)):
            target = raw.split("|")[0].split("#")[0].strip()
            # `[[:space:]]` and friends are POSIX character classes in a regex
            # that happened to be written outside a code span, not wikilinks.
            if target and not POSIX_CLASS_RE.match(target):
                yield lineno, target


class Index:
    """Note-name lookup with three progressively fuzzier maps."""

    def __init__(self, dirs: list[Path]):
        self.exact: dict[str, str] = {}
        self.norm: dict[str, str] = {}
        self.strip: dict[str, str] = {}
        self.ambiguous: dict[str, set[str]] = collections.defaultdict(set)
        self.paths: dict[str, Path] = {}

        for d in dirs:
            if not d.is_dir():
                continue
            for f in sorted(d.glob("*.md")):
                base = f.stem
                self.paths[base] = f
                nb = normalize(base)
                self._put(self.exact, base, base)
                self._put(self.norm, nb, base)
                for p in TYPE_PREFIXES:
                    if nb.startswith(p + "_"):
                        self._put(self.strip, nb[len(p) + 1 :], base)

    def _put(self, m: dict[str, str], key: str, val: str) -> None:
        if key in m and m[key] != val:
            self.ambiguous[key].update({m[key], val})
        else:
            m[key] = val

    def lookup(self, target: str) -> str | None:
        if target in self.exact:
            return target
        key = normalize(target)
        if key in self.ambiguous:
            return None
        return self.norm.get(key) or self.strip.get(key)

    def resolve(self, target: str) -> tuple[str, str | None]:
        """Return (status, name). status in ok|fix|ambiguous|dangling."""
        if target in self.exact:
            return "ok", target
        if normalize(target) in self.ambiguous:
            return "ambiguous", None
        name = self.lookup(target)
        return ("fix", name) if name else ("dangling", None)


def reachable_from(entry: Path, index: Index) -> set[str]:
    """BFS from MEMORY.md over markdown links, wikilinks and superseded_by."""
    seen: set[str] = set()
    queue = collections.deque([entry])
    visited = {entry.resolve()}
    while queue:
        cur = queue.popleft()
        if not cur.is_file():
            continue
        targets = {t for t in MDLINK_RE.findall(cur.read_text(encoding="utf-8", errors="replace"))}
        targets |= {t for _, t in iter_links(cur)}
        if sb := frontmatter(cur).get("metadata.superseded_by"):
            targets.add(sb)
        for t in targets:
            if (name := index.lookup(t)) and name not in seen:
                seen.add(name)
                nxt = index.paths[name].resolve()
                if nxt not in visited:
                    visited.add(nxt)
                    queue.append(index.paths[name])
    return seen


def main() -> int:
    ap = argparse.ArgumentParser(description="Lint the agent knowledge base.")
    ap.add_argument("--apply", action="store_true", help="rewrite fixable links in place")
    ap.add_argument("--check", action="store_true", help="exit 1 on any finding")
    ap.add_argument("--quiet", action="store_true", help="summary block only")
    ap.add_argument("--corpus", action="append", default=[], help="dir to scan (repeatable)")
    ap.add_argument("--index", action="append", default=[], help="dir of notes (repeatable)")
    ap.add_argument("--root", help="project root (default: git toplevel of the cwd)")
    ap.add_argument("--entry", help="index file reachability is measured from")
    ap.add_argument("--index-budget", type=int, default=MEMORY_INDEX_BUDGET,
                    help="bytes the always-loaded index may occupy")
    args = ap.parse_args()

    root = repo_root(args.root)
    mem = memory_dir(root)

    # The memory directory is only a precondition when the defaults are in use.
    # Given explicit dirs the linter must run anywhere — that is what makes it
    # testable against a fixture corpus, and a linter nobody can test is exactly
    # the kind of silent decay it exists to catch.
    if not args.index and not args.corpus and not mem.is_dir():
        print(f"memory dir not found: {mem}\nset CAIRN_MEMORY_DIR, or pass --index/--corpus",
              file=sys.stderr)
        return 2

    index_dirs = [Path(d) for d in args.index] or [mem, root / ".claude" / "rules"]
    corpus_dirs = [Path(d) for d in args.corpus] or [mem, root / "docs"]
    budget = args.index_budget
    index = Index(index_dirs)
    files = sorted({f for d in corpus_dirs if d.is_dir() for f in d.rglob("*.md")})
    # "Notes" are the files in the FIRST index dir: the ones the schema and the
    # reachability rules apply to. Later dirs (rules, shared docs) are link
    # targets, not notes, and judging them by the note schema is noise.
    note_dir = index_dirs[0]
    mem_notes = {n for n, p in index.paths.items() if p.parent == note_dir}

    # ---------------------------------------------------------------- 1. links
    fixes: dict[Path, dict[str, str]] = collections.defaultdict(dict)
    dangling: collections.Counter[str] = collections.Counter()
    ambiguous: collections.Counter[str] = collections.Counter()
    total = ok = 0
    for f in files:
        for _, target in iter_links(f):
            total += 1
            status, resolved = index.resolve(target)
            if status == "ok":
                ok += 1
            elif status == "fix":
                fixes[f][target] = resolved  # type: ignore[arg-type]
            elif status == "ambiguous":
                ambiguous[target] += 1
            else:
                dangling[target] += 1
    fixable = sum(len(v) for v in fixes.values())

    # --------------------------------------------------------------- 2. schema
    schema_errs: list[str] = []
    for name in sorted(mem_notes - {"MEMORY"}):  # the index is a hub, not a note
        fm = frontmatter(index.paths[name])
        if not fm.get("description"):
            schema_errs.append(f"{name}: missing `description` (recall reads it first)")
        ntype = fm.get("metadata.type") or fm.get("type")
        if ntype not in VALID_TYPES:
            schema_errs.append(f"{name}: type={ntype!r} not in {sorted(VALID_TYPES)}")
        elif "type" in fm and "metadata.type" not in fm:
            schema_errs.append(f"{name}: `type` sits above `metadata:` — move it inside")
        st = fm.get("metadata.status")
        if st and st not in VALID_STATUS:
            schema_errs.append(f"{name}: status={st!r} not in {sorted(VALID_STATUS)}")
        sb = fm.get("metadata.superseded_by")
        if st == "superseded" and not sb:
            schema_errs.append(f"{name}: status=superseded requires `superseded_by`")
        if sb and not index.lookup(sb):
            schema_errs.append(f"{name}: superseded_by={sb!r} resolves to nothing")

    # --------------------------------------------------------- 3. reachability
    entry = Path(args.entry) if args.entry else note_dir / "MEMORY.md"
    orphans: list[str] = []
    if entry.is_file():
        live = reachable_from(entry, index)
        orphans = sorted(mem_notes - live - {"MEMORY"})

    # --------------------------------------------------------------- 4. budget
    index_bytes = entry.stat().st_size if entry.is_file() else 0
    over_budget = index_bytes > budget

    # --------------------------------------------------------------- reporting
    rel = lambda p: str(p).replace(f"{root}/", "").replace(str(Path.home()), "~")  # noqa: E731
    pct = 100 * index_bytes / budget if budget else 0

    print()
    print(f"  corpus     {len(files)} files, {len(mem_notes)} memory notes, {total} links")
    print(f"  links      {ok} ok · {fixable} fixable · {len(ambiguous)} ambiguous · {len(dangling)} dangling")
    print(f"  schema     {len(schema_errs)} violations")
    print(f"  orphans    {len(orphans)} unreachable from {entry.name}")
    print(f"  index      {index_bytes:,} B / {budget:,} B budget ({pct:.0f}%)"
          f"{'  ← OVER, archive the oldest lines' if over_budget else ''}")
    print()

    if not args.quiet:
        if fixes:
            print("── fixable links ────────────────────────────────────")
            for f in sorted(fixes):
                for old, new in sorted(fixes[f].items()):
                    print(f"  {rel(f):<46}  [[{old}]] → [[{new}]]")
            print()
        if ambiguous:
            print("── ambiguous (resolve by hand) ──────────────────────")
            for t, n in ambiguous.most_common():
                print(f"  {n:>3}×  [[{t}]] → {', '.join(sorted(index.ambiguous[normalize(t)]))}")
            print()
        if dangling:
            print("── dangling (no note yet — legitimate forward links) ─")
            for t, n in dangling.most_common():
                print(f"  {n:>3}×  [[{t}]]")
            print()
        if schema_errs:
            print("── schema ───────────────────────────────────────────")
            for e in schema_errs:
                print(f"  {e}")
            print()
        if orphans:
            print("── orphaned (written, indexed nowhere, never recalled) ──")
            for o in orphans:
                print(f"  {o}")
            print()

    if args.apply and fixes:
        for f, table in fixes.items():
            text = f.read_text(encoding="utf-8")
            for old, new in table.items():
                text = text.replace(f"[[{old}]]", f"[[{new}]]")
            f.write_text(text, encoding="utf-8")
        print(f"applied {fixable} rewrites across {len(fixes)} files.")
        return 0

    if args.check and (fixable or schema_errs or orphans or over_budget):
        print("FAIL: knowledge base has findings (see above).", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
