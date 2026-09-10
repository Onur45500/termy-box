# Example NDF files for termy-box

Small, safe dataset snippets you can mount or copy into `./dataset/`.

Upstream format docs: [NDF 0.0](https://github.com/gioblu/NPC-Forge/blob/main/docs/dataset.md) and [TCS command security](https://github.com/gioblu/NPC-Forge/blob/main/docs/commands-security.md).

## Files

| File | Purpose |
|------|---------|
| `dataset_example_greeting.json` | Exact-match greeting with marker `EXAMPLE_PING_OK` (no tools) |
| `dataset_example_echo.json` | Harmless `echo` tool intent with `permission: ask` |
| `templates_example_say.json` | Minimal `templates_*.json` NER-style stub using `<\|\|string\|\|>` |

## Try them

```bash
# Copy into the compose mount point
cp examples/dataset/*.json dataset/

docker compose --env-file versions.env run --rm termy "termy box example ping"

# Or mount examples directly
docker compose --env-file versions.env run --rm \
  -v "$PWD/examples/dataset:/dataset:ro" \
  termy "termy box example ping"
```

Validate JSON / required keys:

```bash
bash scripts/validate-dataset.sh examples/dataset
```
