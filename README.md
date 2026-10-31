# Conquer the World

A real-time territory strategy game for Roblox: spawn, expand, fight, and hold the world. Built on the
open-source **RoWorld** (itself a modified **OpenFront**), under the AGPL v3: see [NOTICE.md](NOTICE.md).
The inherited war, economy and network code is theirs; the systems below are this game's own.

## What is ours

* **Eras.** A match has an arc: Dawn, Expansion, Conflict, Reckoning (`src/shared/Data/Eras.luau`).
* **Doctrines.** At each era after the first, every player drafts one of three doctrines, a permanent bend
  of the economy that usually costs something else (`Data/Doctrines.luau`, `Core/SimDoctrines.luau`).
  Nations draft too. Every last-era doctrine grants an active **edict**.
* **Landmarks.** Six kinds of site on the map pay whoever holds the ground; double in the Reckoning
  (`Core/SimLandmarks.luau`, `client/Map/LandmarkLayer.luau`).
* **World events, rivals, game modes** (`Data/WorldEvents`, `Data/Personas` + `Core/SimRivals`, `Data/Modes` + `Core/SimModes`).
* **Six invented maps** (`tools/maps/make_fictional.py`).
* **The commander's career**: Field Orders, medals, the War Room campaign, seasons, the War Report (`Data/Orders`,
  `Medals`, `Missions`, `Season`, `Progress`; `client/UI/CommandCenter`, `WarReport`, `MatchLog`). Cosmetic on purpose.
* **Cartography.** The map is drawn as a war-room chart: ink-dark banded sea, parchment relief land,
  inked borders (`client/Map/MapSurface.luau`, `build_terrain`).
* **Dominion HUD and draft cards** (`client/UI/DominionStrip.luau`, `DoctrineDraft.luau`), an economy-first
  tutorial, a cosmetic career rank (`Data/Career.luau`).

All of it sits behind config flags that `Sim.new` leaves OFF; `Sim.DEFAULTS` is what the shipped game turns
on (Session and ServerMain apply it), so the inherited tests keep proving the base is untouched.

## Working on it

```
node tools/check.js --fast     # licence/branding guards, every Lune test, syntax of every script, rojo build
node tools/check.js            # the same plus the slow simulation benchmarks
node tools/build.js            # build/ConquerTheWorld.rbxl, the place file to open in Studio
lune run tools/map/render_map.luau europe 1500 7 && python tools/map/rgba_to_png.py build/map_europe.rgba
```

Tools expected in `~/tools`: `rojo`, `lune`, `luau`, `luau-lsp` (with Roblox type definitions).
[docs/PLAN.md](docs/PLAN.md) is the plan this was built to, with its audit log; [docs/ASSETS_TODO.md](docs/ASSETS_TODO.md)
says what is ours and what is still thin.

## Before launch

[docs/RELEASE_CHECKLIST.md](docs/RELEASE_CHECKLIST.md) lists the steps only the owner can do. [docs/CHANGELOG.md](docs/CHANGELOG.md) lists what
ships. `lune run tools/balance_probe.luau` plays the War Room with a bot in the player's seat.
