#!/usr/bin/env bash
# Download the pinned NPC-Forge source archive into .build/ for the Docker build.
# Usage: ./scripts/fetch-upstream.sh [NPC_FORGE_REF]
# Reads default REF from versions.env when no argument / env is set.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ -f "${ROOT}/versions.env" ]]; then
  # shellcheck disable=SC1091
  set -a
  # shellcheck source=/dev/null
  source "${ROOT}/versions.env"
  set +a
fi

REF="${1:-${NPC_FORGE_REF:?NPC_FORGE_REF missing — pass an argument or set versions.env}}"
OUT_DIR="${ROOT}/.build"
ARCHIVE="${OUT_DIR}/NPC-Forge-${REF}.tar.gz"
URL="https://github.com/gioblu/NPC-Forge/archive/${REF}.tar.gz"

mkdir -p "${OUT_DIR}"
if [[ -f "${ARCHIVE}" ]]; then
  echo "Already present: ${ARCHIVE}"
  exit 0
fi

echo "Fetching ${URL}"
if command -v curl >/dev/null 2>&1; then
  curl -fsSL "${URL}" -o "${ARCHIVE}"
elif command -v wget >/dev/null 2>&1; then
  wget -qO "${ARCHIVE}" "${URL}"
else
  echo "Need curl or wget to download upstream." >&2
  exit 1
fi

echo "Saved ${ARCHIVE} ($(wc -c < "${ARCHIVE}") bytes)"
