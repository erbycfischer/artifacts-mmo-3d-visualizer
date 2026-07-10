# Official 3D visual client — verification checklist

Use this after bridge + Godot changes. Do not commit tokens.

## Local (no token)

```sh
export PLTCOLLECTS="$HOME/artifacts-racket:${PLTCOLLECTS:-}"
raco test tests/client-test.rkt
racket bridge.rkt
# other terminal:
godot --path godot
```

Expect: hub on `ws://127.0.0.1:8787`, Godot Connect → fixtures or Unauthenticated mode.

## Live official token

```sh
export PLTCOLLECTS="$HOME/artifacts-racket:${PLTCOLLECTS:-}"
export ARTIFACTS_API_TOKEN=your_token_here   # never commit
racket bridge.rkt
godot --path godot
```

## Watch bots (no bot hooks)

```sh
# terminal 1 — this repo
racket bridge.rkt
# terminal 2 — sibling artifacts-racket
cd ~/artifacts-racket && racket examples/apex-bot.rkt
# terminal 3
godot --path godot
```
