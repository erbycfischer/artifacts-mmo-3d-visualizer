# artifacts-mmo-ai-3d-visualizer

Official Artifacts MMO **3D visual client** (Godot + local Racket bridge).

Same live game as [artifactsmmo.com](https://artifactsmmo.com) — alternate 3D view, not a clone.

Bots live in the sibling repo [artifacts-racket](https://github.com/erbycfischer/artifacts-racket). This repo never runs bot strategy; it only renders and plays via the official API.

## Quickstart

```sh
# Bridge needs the sibling bot package on the collect path (HTTP/config helpers):
export PLTCOLLECTS="$HOME/artifacts-racket:${PLTCOLLECTS:-}"
# or: raco pkg install --link ~/artifacts-racket

export ARTIFACTS_API_TOKEN=your_token_here   # or ARTIFACTS_TOKEN
racket bridge.rkt
# other terminal:
godot --path godot
```

In Godot: Connect → Auth (if token not in env) → select character → click tiles → Move / Fight / Gather / Rest.

Default bridge: `ws://127.0.0.1:8787` (`ARTIFACTS_BRIDGE_PORT`).

## Watch bots (no bot hooks)

1. Start this bridge + Godot with your token.
2. Run any bot from `artifacts-racket` (or elsewhere) against the official API.
3. Character motion appears from official `get-my-characters` polling.

## Layout

- `bridge.rkt` — entrypoint
- `bridge/` — session service, WebSocket hub, optional realtime ingest
- `godot/` — Godot 4 project (`project.godot` is the project root)
- `tests/` — bridge protocol tests
- `docs/` — protocol and verification checklist

## Dependency

Uses the `artifacts` Racket collection from **`~/artifacts-racket`** for REST helpers (`artifacts/config`, `artifacts/http`, …). Install/link that package or set `PLTCOLLECTS` as above.

## Docs

- [`docs/visualizer.md`](docs/visualizer.md) — protocol and controls
- [`docs/3d-client-verification.md`](docs/3d-client-verification.md) — live verification checklist
