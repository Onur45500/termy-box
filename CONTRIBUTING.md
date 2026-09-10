# Contributing to termy-box

Thanks for helping improve this **unofficial** Docker packaging of [NPC-Forge](https://github.com/gioblu/NPC-Forge) / TERMy.

## What belongs here vs upstream

| Change type | Where |
|-------------|--------|
| Dockerfile, entrypoint, compose, CI, docs, examples | **this repo** |
| TERMy intents, NDF datasets, FlintParser bugs, NPC-Forge CLI | **[gioblu/NPC-Forge](https://github.com/gioblu/NPC-Forge)** |

Do not fork or patch upstream Python sources in PRs here.

## Prerequisites

- Docker with Buildx
- Bash (Git Bash / WSL on Windows is fine for scripts)

## Local setup

```bash
# 1. Fetch the pinned upstream archive (reads versions.env)
bash scripts/fetch-upstream.sh

# 2. Build
docker compose --env-file versions.env build

# 3. Smoke
docker run --rm -it termy-box:local "how are you"
docker run --rm -e TERMY_PROPOSE_ONLY=1 termy-box:local "list files"
bash scripts/validate-dataset.sh examples/dataset
```

## Pull requests

1. Keep changes focused (packaging, docs, CI, examples).
2. Update [`CHANGELOG.md`](CHANGELOG.md) for user-visible changes.
3. If you bump upstream, change **only** [`versions.env`](versions.env) (`NPC_FORGE_REF`), then re-run `scripts/fetch-upstream.sh`.
4. Do not commit `.build/*.tar.gz` archives.
5. Be respectful — see [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md).

## Security-sensitive changes

Mounting host paths or weakening propose-only defaults needs a clear security rationale in the PR. See [`SECURITY.md`](SECURITY.md).
