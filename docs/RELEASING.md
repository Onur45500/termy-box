# Releasing termy-box

Maintainer checklist for publishing images to GHCR.

## Prerequisites

- Repo: https://github.com/Onur45500/termy-box
- Actions permissions: `packages: write`, `id-token: write` (see workflow)
- Pins are correct in [`versions.env`](../versions.env)

## Steps

1. Ensure `main` is green (smoke job builds + propose-only + dataset validate).
2. Confirm GHCR package visibility for `termy-box` (public recommended for OSS).
3. `IMAGE_SOURCE` in `versions.env` should be `https://github.com/Onur45500/termy-box` (CI also overrides from `github.repository`).
4. Update [`CHANGELOG.md`](../CHANGELOG.md) and move Unreleased notes into the new version.
5. Tag and push (from your machine):

   ```bash
   git tag v0.2.0
   git push origin v0.2.0
   ```

6. Verify:

   ```bash
   docker pull ghcr.io/onur45500/termy-box:v0.2.0
   docker run --rm -it ghcr.io/onur45500/termy-box:v0.2.0 "how are you"
   cosign verify \
     --certificate-identity-regexp 'https://github.com/Onur45500/termy-box/.*' \
     --certificate-oidc-issuer https://token.actions.githubusercontent.com \
     ghcr.io/onur45500/termy-box:v0.2.0
   ```

## Notes

- Image name must stay clearly **unofficial** (`termy-box`, not an official NPC-Forge name).
- Weekly `upstream-bump` opens PRs only — never auto-merges.
