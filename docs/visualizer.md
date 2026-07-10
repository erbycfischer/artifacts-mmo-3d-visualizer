# Official Artifacts custom 3D visual client

This is a **visual-only custom client** for the **official Artifacts MMO**, not a clone or private server.

- Same live game as [artifactsmmo.com](https://artifactsmmo.com) / the official 2D web client.
- Godot renders official state in 3D; the Racket **bridge** (`bridge.rkt`) holds the token and calls official REST (and optional realtime).
- **Bots never use this client.** Run bots from `artifacts-racket` (or any official API client); watch them here via official character polling.

Respect rate limits and the game ToS. Use your own token; never commit it.

## Launch

```sh
export PLTCOLLECTS="$HOME/artifacts-racket:${PLTCOLLECTS:-}"
export ARTIFACTS_API_TOKEN=your_token_here
racket bridge.rkt
# other terminal:
godot --path godot
```

In Godot: Connect → Auth with token → select character → click tiles → Move/Fight/Gather/Rest; bank/GE/NPC/tasks when on matching tiles.

## Watch bots (no bot hooks)

1. Start the bridge + Godot with your token.
2. Run any bot against the official API.
3. Character motion appears from official `get-my-characters` polling — **no visualization code in the bot.**

## Protocol

Local WebSocket `ws://127.0.0.1:8787` (or `ARTIFACTS_BRIDGE_PORT`), envelope `{ type, timestamp, data }`.

### Server → Godot

- `world.snapshot` — maps, characters (own + `other: true`), events, raids
- `session.status` — authenticated, characters, selected, pending_items, error
- `action.result` — manual play feedback
- `account.logs` — recent log lines
- `bot.decision` / `market.signal` — fixture/offline samples only

### Godot → bridge

- `session.auth` — `{ token }` (local only; never logged)
- `session.logout`
- `player.select` — `{ character }`
- `player.action` — `{ character, action, payload }` → official REST
- `ui.subscribe`

## Verification

See [`3d-client-verification.md`](3d-client-verification.md).
