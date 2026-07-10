## Learned User Preferences

- This repo is the official Artifacts **3D visual client** only (Godot + local bridge).
- Bot strategy and `#lang artifacts` live in the sibling repo `artifacts-racket`.
- Never commit tokens or secrets.
- Never add `Co-Authored-By` trailers on commits, PRs, or pushes.

## Learned Workspace Facts

- Path: `/home/dirt/artifacts-mmo-ai-3d-visualizer` — independent git repo from `artifacts-racket`.
- Run bridge with `PLTCOLLECTS="$HOME/artifacts-racket:" racket bridge.rkt`.
- Open Godot at `godot/` (`godot --path godot`).
- Bridge polls official Artifacts REST; bots appear via character state with zero bot hooks.
