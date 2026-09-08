#!/usr/bin/env python3
"""Merge cairn's hook entries into an existing .claude/settings.json.

Idempotent by construction: a hook is identified by its command string, so a
second run adds nothing. The naive version of this script appends the whole
block each time, and the symptom — every hook running two, then three times —
looks like a performance problem rather than an install bug.

Never destructive: the existing file is backed up first (to a timestamped name
that is never reused), unrelated keys are left untouched, and an unparseable
file aborts the merge rather than replacing it.
"""
from __future__ import annotations

import json
import shutil
import sys
import time
from pathlib import Path


def commands(entry: dict) -> set[str]:
    return {h.get("command", "") for h in entry.get("hooks", [])}


def main() -> int:
    dest, src = Path(sys.argv[1]), Path(sys.argv[2])
    incoming = json.loads(src.read_text(encoding="utf-8"))["hooks"]

    existing: dict = {}
    if dest.is_file():
        try:
            existing = json.loads(dest.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            print(f"  abort     {dest} is not valid JSON ({exc}) — merge skipped", file=sys.stderr)
            return 1
        # Timestamped, and never overwritten. A fixed `.bak` name means the
        # SECOND install overwrites the backup with the already-merged file, so
        # the original settings are gone exactly when someone needs them back.
        backup = dest.with_name(f"{dest.name}.{int(time.time())}.bak")
        while backup.exists():
            backup = dest.with_name(f"{dest.name}.{int(time.time())}-{id(backup) % 1000}.bak")
        shutil.copy2(dest, backup)
        print(f"  backup    {backup.name}")

    hooks = existing.setdefault("hooks", {})
    added = 0
    for event, entries in incoming.items():
        current = hooks.setdefault(event, [])
        present = {c for e in current for c in commands(e)}
        for entry in entries:
            new = [h for h in entry.get("hooks", []) if h.get("command") not in present]
            if not new:
                continue
            merged = dict(entry)
            merged["hooks"] = new
            current.append(merged)
            added += len(new)

    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(json.dumps(existing, indent=2) + "\n", encoding="utf-8")
    print(f"  merge     {dest.name}: {added} hook(s) added"
          f"{' (already up to date)' if added == 0 else ''}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
