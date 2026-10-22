# You Piece of Ship

**You Piece of Ship is a 4-player co-op party game where you steer, read charts, stoke the engine and patch the hull of one rickety cargo ship to reach port, but every breakdown changes how the ship handles, so one bad call snowballs into a disaster you can almost save.**

Built with Godot 4.7.2. Design: [DESIGN.md](DESIGN.md) · Backlog: [BACKLOG.md](BACKLOG.md) · Playtests: [docs/PLAYTEST_LOG.md](docs/PLAYTEST_LOG.md)

## Getting started
1. Install [Godot 4.7.2](https://godotengine.org/download) and [Git LFS](https://git-lfs.com) (`git lfs install`).
2. Clone the repo and open `project.godot` in Godot.

## Running tests
Tests use [GUT](https://github.com/bitwes/Gut). BDD specs live in `features/`, tests in `tests/`.
```bash
godot --headless --import
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
```
CI runs the same suite on every push and pull request.

## Workflow
Hypothesis → spec → test → greybox → playtest → keep or revert → update docs. See [CLAUDE.md](CLAUDE.md).
