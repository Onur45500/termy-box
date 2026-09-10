#!/usr/bin/env bash
# Validate NDF dataset_*.json / templates_*.json files.
# Checks: JSON parse + each entry has "input" and ("message" or "tools").
# Usage: bash scripts/validate-dataset.sh [dir...]
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGETS=("$@")
if [[ ${#TARGETS[@]} -eq 0 ]]; then
  TARGETS=("${ROOT}/examples/dataset")
  if [[ -d "${ROOT}/dataset" ]]; then
    TARGETS+=("${ROOT}/dataset")
  fi
fi

# Drop empty dataset dir from defaults if it has no NDF files
FILTERED=()
for t in "${TARGETS[@]}"; do
  if [[ -d "${t}" ]]; then
    if find "${t}" \( -name 'dataset_*.json' -o -name 'templates_*.json' \) | grep -q .; then
      FILTERED+=("${t}")
    elif [[ "${t}" == */examples/dataset ]]; then
      echo "validate-dataset: no files under ${t}" >&2
      exit 1
    fi
  else
    FILTERED+=("${t}")
  fi
done
TARGETS=("${FILTERED[@]}")

python3 - "${TARGETS[@]}" <<'PY'
from __future__ import annotations

import json
import sys
from pathlib import Path

paths: list[Path] = []
args = sys.argv[1:] or ["examples/dataset", "dataset"]
for arg in args:
    p = Path(arg)
    if p.is_file():
        paths.append(p)
    elif p.is_dir():
        paths.extend(sorted(p.rglob("dataset_*.json")))
        paths.extend(sorted(p.rglob("templates_*.json")))
    else:
        # Empty optional dirs are fine
        if p.name == "dataset" and not p.exists():
            continue
        print(f"validate-dataset: path not found: {p}", file=sys.stderr)
        sys.exit(1)

# De-dupe while preserving order
seen: set[Path] = set()
uniq: list[Path] = []
for p in paths:
    rp = p.resolve()
    if rp in seen:
        continue
    seen.add(rp)
    uniq.append(p)

if not uniq:
    print("validate-dataset: no dataset_*/templates_*.json files found", file=sys.stderr)
    sys.exit(1)

errors = 0
for path in uniq:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:  # noqa: BLE001 — report and continue
        print(f"FAIL {path}: invalid JSON ({exc})", file=sys.stderr)
        errors += 1
        continue

    if not isinstance(data, list):
        print(f"FAIL {path}: root must be a JSON array", file=sys.stderr)
        errors += 1
        continue

    if len(data) == 0:
        print(f"FAIL {path}: empty array", file=sys.stderr)
        errors += 1
        continue

    for i, entry in enumerate(data):
        if not isinstance(entry, dict):
            print(f"FAIL {path}[{i}]: entry must be an object", file=sys.stderr)
            errors += 1
            continue
        if "input" not in entry:
            print(f"FAIL {path}[{i}]: missing required key 'input'", file=sys.stderr)
            errors += 1
        if "message" not in entry and "tools" not in entry:
            print(
                f"FAIL {path}[{i}]: need 'message' and/or 'tools'",
                file=sys.stderr,
            )
            errors += 1

    if errors == 0:
        print(f"OK   {path} ({len(data)} entries)")

if errors:
    print(f"validate-dataset: {errors} error(s)", file=sys.stderr)
    sys.exit(1)

print(f"validate-dataset: {len(uniq)} file(s) OK")
PY
