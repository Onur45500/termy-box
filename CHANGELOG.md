# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Open-source community files (`CONTRIBUTING`, `SECURITY`, `CODE_OF_CONDUCT`)
- README visuals under `docs/images/`
- Issue templates and `docs/RELEASING.md`

## [0.2.0] - 2026-09-10

### Added

- Digest-pinned Debian base and centralized pins in `versions.env`
- Propose-only mode (`TERMY_PROPOSE_ONLY=1`) via in-process engine (blocks `yolo`)
- Compose profiles `workspace` and `workspace-exec`
- Example NDF pack + `scripts/validate-dataset.sh`
- CI: SBOM, provenance, cosign keyless; weekly upstream-bump workflow
- Optional Flask server mode (`TERMY_MODE=server`)

## [0.1.0] - 2026-09-10

### Added

- Initial multi-stage Docker packaging of NPC-Forge/TERMy
- Non-root `termy` user, PATH fix, custom `/dataset` mount
- docker-compose one-shot + GHCR publish workflow scaffold
