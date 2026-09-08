#!/usr/bin/env python3
"""Check that every relative markdown link resolves to a file that exists.

A broken link in a README is a first impression, and it is the kind of defect
that nothing else catches: it renders fine, it reads fine, and it is only wrong
when someone clicks. Cheap to check, so it is checked.

Links inside fenced blocks and code spans are examples, not links, and are
skipped. External links (http, mailto) and bare anchors are out of scope: verifying those
needs the network, and a check that fails when the network does is a check people
disable.

Usage: check-links.py [paths...]      # default: the repository, minus fixtures
Exit:  0 clean · 1 broken links found
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

LINK = re.compile(r"\]\(([^)\s]+)\)")
FENCE = re.compile(r"^\s*(```|~~~)")
INLINE_CODE = re.compile(r"`[^`]*`")
SKIP_DIRS = {".git", "node_modules", "__pycache__", ".local"}


def markdown_files(roots: list[Path]) -> list[Path]:
    out: list[Path] = []
    for root in roots:
        if root.is_file():
            out.append(root)
            continue
        for p in sorted(root.rglob("*.md")):
            if SKIP_DIRS & set(p.parts):
                continue
            # Fixtures hold deliberately broken links; the harness points at
            # them explicitly, the same way the leak scanner treats its own.
            if not explicit and "fixtures" in p.parts:
                continue
            out.append(p)
    return out


explicit = len(sys.argv) > 1
roots = [Path(a) for a in sys.argv[1:]] or [Path(".")]
broken = 0

for f in markdown_files(roots):
    in_fence = False
    for lineno, line in enumerate(f.read_text(encoding="utf-8", errors="replace").splitlines(), 1):
        # A link inside a fenced block or a code span is an EXAMPLE of a link,
        # not a link. Excluded here rather than filtered downstream, so the
        # counts this script prints are honest.
        if FENCE.match(line):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        for target in LINK.findall(INLINE_CODE.sub("", line)):
            if target.startswith(("http://", "https://", "mailto:", "#")):
                continue
            path = target.split("#")[0]
            if not path:
                continue
            if not (f.parent / path).exists():
                print(f"BROKEN {f}:{lineno}: {target}")
                broken += 1

if broken:
    print(f"\ncheck-links: {broken} broken link(s).", file=sys.stderr)
    sys.exit(1)
print("check-links: clean")
