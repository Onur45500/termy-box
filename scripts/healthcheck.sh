#!/usr/bin/env bash
# Smoke / health check for termy-box.
# - Server mode: HTTP check against the Flask gateway
# - Otherwise: piped-stdin TERMy query (no TTY required)
set -euo pipefail

export PATH="${HOME}/.local/bin:${PATH}"

FORGE_DIR="${FORGE_DIR:-$HOME/.local/share/npc-forge}"
TIMEOUT_SECS="${HEALTHCHECK_TIMEOUT:-8}"

if [[ ! -x "${HOME}/.local/bin/termy" ]]; then
  echo "healthcheck: termy binary missing" >&2
  exit 1
fi

# When the Flask server is expected, prefer an HTTP probe.
if [[ "${TERMY_MODE:-cli}" == "server" ]]; then
  if command -v curl >/dev/null 2>&1; then
    if curl -fsS --max-time "${TIMEOUT_SECS}" \
         -H 'Content-Type: application/json' \
         -d '{"message":"how are you"}' \
         "http://127.0.0.1:5000/api/chat/termy" >/dev/null; then
      exit 0
    fi
    echo "healthcheck: server HTTP probe failed" >&2
    exit 1
  fi
fi

# CLI smoke: pipe a trivial prompt (avoids TTY/args quirk)
# Capture output; accept any non-empty response that looks like TERMy meta line.
out="$(echo "how are you" | timeout "${TIMEOUT_SECS}" termy 2>/dev/null || true)"
if echo "${out}" | grep -Eqi 'TERMy|Confidence|Response:'; then
  exit 0
fi

echo "healthcheck: TERMy did not respond as expected" >&2
echo "${out}" >&2
exit 1
