# Security Policy

## Supported versions

This project packages a pinned NPC-Forge/TERMy commit (see [`versions.env`](versions.env)). Only the latest published image tags (`latest` and the newest `v*` release) receive packaging fixes.

## Command execution risk

TERMy can translate natural language into **real shell commands** and may execute them (`ask` confirm, `yolo`, or `--yes`).

- Prefer **propose-only** (`TERMY_PROPOSE_ONLY=1` or compose profile `workspace`) when mounting host directories.
- Do **not** run with `--privileged` or extra capabilities.
- Container isolation does **not** protect bind-mounted host paths.

## Reporting a vulnerability

Please report packaging or distribution security issues privately when possible:

1. Use GitHub **Security Advisories** on [Onur45500/termy-box](https://github.com/Onur45500/termy-box/security/advisories/new), or
2. Open a private maintainer contact via a GitHub issue marked `security` if advisories are unavailable.

Include: image tag/digest, reproduction steps, and impact.

For vulnerabilities in NPC-Forge/TERMy itself, report **upstream**: https://github.com/gioblu/NPC-Forge
