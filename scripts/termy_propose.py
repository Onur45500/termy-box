#!/usr/bin/env python3
"""Propose-only runner for TERMy — never executes tool commands.

Loads the installed NPC-Forge engine in-process (same offline path as the
termy CLI fallback) and prints the match / proposed command(s) without
calling subprocess. Does not modify upstream sources.

This blocks both `ask` and `yolo` execution paths, and ignores --yes.
"""
from __future__ import annotations

import json
import os
import sys
from pathlib import Path


def _forge_dir() -> Path:
    env = os.environ.get("FORGE_DIR")
    if env:
        return Path(env)
    return Path.home() / ".local" / "share" / "npc-forge"


def _print_banner() -> None:
    print(
        "termy-box: PROPOSE-ONLY — engine match only; no shell commands will run.",
        file=sys.stderr,
    )


def main(argv: list[str]) -> int:
    # argv: termy_propose.py <ignored-termy-bin> [termy args...]
    args = argv[2:] if len(argv) > 1 else argv[1:]

    # Strip wrapper-only flags / binary name noise
    query_parts: list[str] = []
    skip_yes = False
    i = 0
    while i < len(args):
        a = args[i]
        if a in {"--yes", "-y"}:
            print(
                "termy-box: propose-only ignores --yes/-y (commands still not run).",
                file=sys.stderr,
            )
            skip_yes = True
            i += 1
            continue
        if a == "--npc":
            i += 2
            continue
        if a.startswith("-"):
            i += 1
            continue
        query_parts.append(a)
        i += 1

    if not query_parts and not sys.stdin.isatty():
        query = sys.stdin.read().strip()
    else:
        query = " ".join(query_parts).strip()

    if not query:
        print("termy-box: propose-only requires a query", file=sys.stderr)
        return 2

    _print_banner()
    if skip_yes:
        pass

    forge = _forge_dir()
    if str(forge) not in sys.path:
        sys.path.insert(0, str(forge))

    try:
        from registry import get_npc_engine
    except Exception as exc:  # noqa: BLE001
        print(f"termy-box: failed to import registry: {exc}", file=sys.stderr)
        return 1

    engine = get_npc_engine("termy")
    if engine is None:
        print("termy-box: NPC engine 'termy' not found", file=sys.stderr)
        return 1

    try:
        result = engine.process_messages(query)
    except Exception as exc:  # noqa: BLE001
        print(f"termy-box: engine error: {exc}", file=sys.stderr)
        return 1

    if not isinstance(result, dict):
        print(json.dumps(result, indent=2, default=str))
        return 0

    status = str(result.get("status", "unknown"))
    confidence = float(result.get("confidence", 0.0) or 0.0)
    response = result.get("response") or result.get("description") or ""
    thinking = result.get("thinking") or ""
    permission = result.get("permission", "ask")
    tools = result.get("tools") or []

    print(f"\nTERMy | {status} | Confidence: {confidence * 100:.2f}%\n")
    if thinking:
        print(f"Thinking: {thinking}\n")

    commands: list[str] = []
    for tool in tools:
        # tools may be list of list/dict depending on engine shape
        entries = tool if isinstance(tool, list) else [tool]
        for entry in entries:
            if not isinstance(entry, dict):
                continue
            args_obj = entry.get("arguments") or {}
            if isinstance(args_obj, dict) and "command" in args_obj:
                commands.append(str(args_obj["command"]))
                expl = args_obj.get("explanation") or ""
                print(f"Proposed command: {args_obj['command']}")
                if expl:
                    print(f"Description: {expl}")
                print()

    if response:
        print(f"Response: {response}\n")

    print(f"permission (dataset): {permission}")
    if commands:
        print(
            f"termy-box: propose-only blocked {len(commands)} command(s) — not executed."
        )
    else:
        print("termy-box: no shell commands in this match.")

    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
