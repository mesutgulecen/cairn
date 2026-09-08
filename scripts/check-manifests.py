#!/usr/bin/env python3
"""Validate the plugin manifests against the documented schema.

Schema read from the official reference on 2026-09-08:
  code.claude.com/docs/en/plugins-reference
  code.claude.com/docs/en/plugin-marketplaces

This does NOT prove an install works — only a real `/plugin marketplace add`
does that, and that is a user action this script cannot take. What it does prove
is that the manifests are structurally valid and that every path they name
exists, which is where a hand-written manifest actually goes wrong.

Usage: check-manifests.py [marketplace.json] [plugin.json]
Exit:  0 valid · 1 invalid
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

# Documented plugin components. `rules/` is deliberately absent: it is NOT a
# plugin component — project rules load from the workspace's .claude/rules/, so
# a plugin install does not deliver them. That asymmetry is why the installer is
# the primary path, and it is worth failing loudly if anyone later assumes
# otherwise.
COMPONENT_DIRS = ("commands", "agents", "skills", "hooks", "workflows")

errors: list[str] = []


def need(obj: dict, key: str, where: str, kind=str) -> None:
    if key not in obj:
        errors.append(f"{where}: missing required field {key!r}")
    elif not isinstance(obj[key], kind):
        errors.append(f"{where}: {key!r} must be {kind.__name__}")


def check_marketplace(path: Path) -> None:
    data = json.loads(path.read_text(encoding="utf-8"))
    where = path.name
    need(data, "name", where)
    need(data, "owner", where, dict)
    need(data, "plugins", where, list)
    if isinstance(data.get("owner"), dict):
        need(data["owner"], "name", f"{where}:owner")
    for i, entry in enumerate(data.get("plugins", [])):
        at = f"{where}:plugins[{i}]"
        need(entry, "name", at)
        if "source" not in entry:
            errors.append(f"{at}: missing required field 'source'")
        elif isinstance(entry["source"], str) and entry["source"].startswith("."):
            target = (path.parent.parent / entry["source"]).resolve()
            if not target.is_dir():
                errors.append(f"{at}: source {entry['source']!r} does not exist")


def check_plugin(path: Path) -> None:
    data = json.loads(path.read_text(encoding="utf-8"))
    where = path.name
    need(data, "name", where)
    root = path.parent.parent
    for key in ("hooks", "skills", "commands", "agents", "workflows", "mcpServers"):
        val = data.get(key)
        for rel in ([val] if isinstance(val, str) else val or []):
            if isinstance(rel, str) and not (root / rel).exists():
                errors.append(f"{where}: {key} path {rel!r} does not exist")
    present = [d for d in COMPONENT_DIRS if (root / d).exists()]
    if not present:
        errors.append(f"{where}: plugin root has none of {COMPONENT_DIRS}")
    if (root / "rules").is_dir():
        print(f"  note: {root.name}/rules/ is not a plugin component — "
              "it is delivered by install/install.sh, not by a plugin install")


args = sys.argv[1:] or [".claude-plugin/marketplace.json", "plugin/.claude-plugin/plugin.json"]
for a in args:
    p = Path(a)
    if not p.is_file():
        errors.append(f"{a}: not found")
    elif "marketplace" in p.name:
        check_marketplace(p)
    else:
        check_plugin(p)

if errors:
    for e in errors:
        print(f"INVALID {e}")
    print(f"\ncheck-manifests: {len(errors)} problem(s).", file=sys.stderr)
    sys.exit(1)
print("check-manifests: valid")
