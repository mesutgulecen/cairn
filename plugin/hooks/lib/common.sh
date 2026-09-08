#!/usr/bin/env bash
# Shared helpers for cairn hooks. Source it; do not execute it.
#
# Every hook here obeys two rules learned the hard way:
#
#   * A hook that cannot do its job exits 0. A broken guard must never be able
#     to trap a session — the failure mode of a blocking hook is a developer who
#     disables all hooks, which costs far more than the one check it performed.
#   * `$?` is captured on the line immediately after the command that produced
#     it. A pipeline or a command substitution in between resets it, and a check
#     that reports the opposite of the truth is worse than no check.

# Project root, preferring what the harness tells us.
cairn_root() {
  printf '%s' "${CLAUDE_PROJECT_DIR:-$(pwd)}"
}

# Read a PostToolUse/PreToolUse payload from stdin and print tool_input.file_path.
# Prints an empty string when the payload is absent or malformed — callers treat
# that as "not my business" and exit 0.
cairn_edited_file() {
  python3 -c 'import json,sys
try:
    print(json.load(sys.stdin).get("tool_input", {}).get("file_path", ""))
except Exception:
    print("")' 2>/dev/null || printf ''
}

# cairn_config <dotted.key> <default>
# Reads .cairn/config.json from the project root. Absent file, absent key and
# malformed JSON all fall back to the default: configuration is an override,
# never a precondition.
cairn_config() {
  local key="$1" default="${2-}"
  python3 -c '
import json, os, sys
key, default = sys.argv[1], sys.argv[2]
path = os.path.join(sys.argv[3], ".cairn", "config.json")
try:
    with open(path, encoding="utf-8") as fh:
        node = json.load(fh)
    for part in key.split("."):
        node = node[part]
except Exception:
    print(default); raise SystemExit
if isinstance(node, list):
    print("\n".join(str(x) for x in node))
elif isinstance(node, bool):
    print("true" if node else "false")
else:
    print(node)
' "$key" "$default" "$(cairn_root)" 2>/dev/null || printf '%s' "$default"
}

# Non-blocking advice back to the model (exit 0 keeps the turn going).
cairn_emit_context() {
  local event="$1" msg="$2"
  python3 -c '
import json, sys
print(json.dumps({"hookSpecificOutput": {
    "hookEventName": sys.argv[1],
    "additionalContext": sys.argv[2],
}}))' "$event" "$msg" 2>/dev/null || true
}
