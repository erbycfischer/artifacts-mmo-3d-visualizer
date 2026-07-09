# Godot Visualizer

Godot owns rendering only. Racket remains the source of truth for bot decisions and world state.

## Run

```sh
godot --path godot/client
```

On startup the client loads offline fixtures from `godot/client/fixtures/`, then tries `ws://127.0.0.1:8787`.

## Protocol

Expected JSON messages:

- `world.snapshot` with `maps`, `characters`, `routes`, `events`, `raids`
- `bot.decision` with `character`, `action`, `reason`
- `market.signal` with `code`, `spread`, `score`, optional `x`/`y`/`layer`

## Controls

- WASD: pan
- Middle-drag: orbit
- Wheel: zoom
- Left-click tile: select
