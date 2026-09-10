#!/usr/bin/env bash
# termy-safe.sh — run TERMy match in propose-only mode (never executes tools).
# Used when TERMY_PROPOSE_ONLY=1. Does not modify upstream TERMy.
set -euo pipefail

TERMY_BIN="${TERMY_BIN:-$(command -v termy)}"
PROPOSE_PY="${PROPOSE_PY:-$HOME/scripts/termy_propose.py}"

if [[ ! -f "${PROPOSE_PY}" ]]; then
  echo "termy-safe: missing ${PROPOSE_PY}" >&2
  exit 1
fi

# Refuse --yes in propose-only (wrapper also ignores it; fail closed for clarity).
for arg in "$@"; do
  if [[ "${arg}" == "--yes" ]] || [[ "${arg}" == "-y" ]]; then
    echo "termy-safe: refusing --yes/-y while TERMY_PROPOSE_ONLY=1" >&2
    exit 2
  fi
done

# Pass through for the Python helper's argv shape: <bin> [args...]
exec python3 "${PROPOSE_PY}" "${TERMY_BIN:-termy}" "$@"
