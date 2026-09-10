#!/usr/bin/env bash
# termy-box entrypoint — wraps npc-forge/termy without modifying upstream.
# Modes: one-shot (args), interactive shell (no args), server (TERMY_MODE=server).
# Propose-only: TERMY_PROPOSE_ONLY=1 or first arg `propose`.
set -euo pipefail

FORGE_DIR="${FORGE_DIR:-$HOME/.local/share/npc-forge}"
TERMY_DATASET_DIR="${FORGE_DIR}/npcs/termy/dataset"
DATASET_MOUNT="${DATASET_MOUNT:-/dataset}"
BIN_DIR="${HOME}/.local/bin"
SAFE_WRAPPER="${HOME}/scripts/termy-safe.sh"

die() {
  echo "termy-box: ERROR: $*" >&2
  exit 1
}

require_binaries() {
  if [[ ! -x "${BIN_DIR}/termy" ]]; then
    die "termy binary missing at ${BIN_DIR}/termy — image is broken or incomplete."
  fi
  if [[ ! -x "${BIN_DIR}/npc-forge" ]]; then
    die "npc-forge binary missing at ${BIN_DIR}/npc-forge — image is broken or incomplete."
  fi
  if ! command -v termy >/dev/null 2>&1; then
    die "termy not found on PATH (${PATH})."
  fi
  if ! command -v npc-forge >/dev/null 2>&1; then
    die "npc-forge not found on PATH (${PATH})."
  fi
}

# Copy custom NDF files from the mount (top-level and one subdirectory deep).
apply_custom_dataset() {
  if [[ ! -d "${DATASET_MOUNT}" ]]; then
    return 0
  fi

  if ! find "${DATASET_MOUNT}" -maxdepth 2 -type f \
        \( -name 'dataset_*.json' -o -name 'templates_*.json' \) \
        -print -quit | grep -q .; then
    return 0
  fi

  mkdir -p "${TERMY_DATASET_DIR}"
  echo "termy-box: loading custom dataset from ${DATASET_MOUNT} ..." >&2
  local copied=0
  local f
  while IFS= read -r -d '' f; do
    cp -f "${f}" "${TERMY_DATASET_DIR}/"
    echo "termy-box:   + $(basename "${f}")" >&2
    copied=$((copied + 1))
  done < <(find "${DATASET_MOUNT}" -maxdepth 2 -type f \
            \( -name 'dataset_*.json' -o -name 'templates_*.json' \) -print0)

  echo "termy-box: copied ${copied} NDF file(s) into ${TERMY_DATASET_DIR}" >&2
}

print_usage_banner() {
  cat <<'EOF'
termy-box — unofficial Docker packaging of NPC-Forge / TERMy

Usage:
  docker run --rm -it ghcr.io/onur45500/termy-box:latest "how are you"
  docker run --rm -it ghcr.io/onur45500/termy-box:latest          # interactive shell
  docker run --rm -it -e TERMY_PROPOSE_ONLY=1 ... "list files"  # print cmds, don't run
  docker run --rm -it -p 5000:5000 -e TERMY_MODE=server \
    ghcr.io/onur45500/termy-box:latest                            # web UI

Inside this shell, run:  termy <your prompt>
Web UI (server mode):    http://localhost:5000/termy/chat/

EOF
}

print_propose_banner() {
  cat <<'EOF' >&2
termy-box: ══════════════════════════════════════════════════════
termy-box: PROPOSE-ONLY is ON — intents are resolved in-process;
termy-box: matched shell commands are shown and NEVER executed
termy-box: (including NDF permission=yolo). --yes is refused.
termy-box: ══════════════════════════════════════════════════════
EOF
}

print_no_tty_exec_warning() {
  if [[ ! -t 0 ]] && [[ "${TERMY_PROPOSE_ONLY:-0}" != "1" ]]; then
    echo "termy-box: WARNING: no TTY — TERMy cannot reliably prompt Yes/No." >&2
    echo "termy-box:          Use -it for confirms, or TERMY_PROPOSE_ONLY=1 / propose." >&2
  fi
}

run_termy() {
  if [[ "${TERMY_PROPOSE_ONLY:-0}" == "1" ]]; then
    print_propose_banner
    if [[ ! -x "${SAFE_WRAPPER}" ]]; then
      die "propose-only wrapper missing at ${SAFE_WRAPPER}"
    fi
    "${SAFE_WRAPPER}" "$@"
    return $?
  fi
  termy "$@"
}

start_server() {
  local py="${FORGE_DIR}/venv/bin/python3"
  [[ -x "${py}" ]] || die "NPC-Forge venv python missing at ${py}"

  echo "termy-box: starting NPC-Forge Flask server on 0.0.0.0:5000" >&2
  echo "termy-box: open http://localhost:5000/termy/chat/  (chat UI)" >&2
  # Upstream server.py hardcodes 127.0.0.1; invoke the app ourselves so Docker
  # port publishing works — no upstream source is modified.
  cd "${FORGE_DIR}"
  exec "${py}" -c "from server import app; app.run(host='0.0.0.0', port=5000, debug=False)"
}

run_oneshot() {
  print_no_tty_exec_warning
  if [[ -t 0 ]]; then
    run_termy "$@"
    exit $?
  fi

  # Without a TTY, TERMy reads stdin and ignores argv. Feed our args as stdin
  # unless propose-only (needs a PTY via termy_propose.py / termy-safe).
  if [[ "${TERMY_PROPOSE_ONLY:-0}" == "1" ]]; then
    echo "termy-box: tip: no TTY — propose-only uses in-process engine (no shell)." >&2
    run_termy "$@"
    exit $?
  fi

  echo "termy-box: tip: no TTY detected — piping your prompt into termy." >&2
  echo "termy-box:      for interactive confirms use: docker run --rm -it ..." >&2
  local query="$*"
  printf '%s\n' "${query}" | termy
  exit $?
}

# --- main -------------------------------------------------------------------

require_binaries
apply_custom_dataset

# Explicit propose-only via first argument
if [[ "${1:-}" == "propose" ]]; then
  shift
  export TERMY_PROPOSE_ONLY=1
fi

# Explicit server mode via env or first argument
if [[ "${TERMY_MODE:-cli}" == "server" ]] || [[ "${1:-}" == "server" ]]; then
  if [[ "${1:-}" == "server" ]]; then
    shift
  fi
  start_server
fi

# Pass-through for common utilities (whoami, bash, healthcheck helpers)
if [[ "${1:-}" == "whoami" ]] || [[ "${1:-}" == "id" ]] || [[ "${1:-}" == "bash" ]] \
   || [[ "${1:-}" == "sh" ]] || [[ "${1:-}" == "env" ]] || [[ "${1:-}" == "ls" ]]; then
  exec "$@"
fi

if [[ "$#" -gt 0 ]]; then
  run_oneshot "$@"
fi

# No args: piped stdin → one-shot termy; otherwise interactive shell
if [[ ! -t 0 ]]; then
  if [[ "${TERMY_PROPOSE_ONLY:-0}" == "1" ]]; then
    die "propose-only with piped stdin and no args is unsupported; pass a query argument."
  fi
  exec termy
fi

print_usage_banner
if [[ "${TERMY_PROPOSE_ONLY:-0}" == "1" ]]; then
  print_propose_banner
  # Shell convenience: alias termy → safe wrapper for this session
  export TERMY_BIN="${BIN_DIR}/termy"
  # shellcheck disable=SC2016
  echo 'alias termy="$HOME/scripts/termy-safe.sh"' >> "${HOME}/.bashrc"
fi
exec bash
