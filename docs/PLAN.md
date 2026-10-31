# Conquer the World: plan to make it its own game

Status: COMMITTED as draft 4, after three audit rounds (self, advisor, independent agent). Round 4 (advisor) found three small fixes and a better phase order; both are folded in below. No further audit before building; each phase ends with its own gate.

## Thesis

RoWorld is a very good *sandbox*: every match is the same arc (spawn, expand, war, maybe nukes) and every
player is the same player. A re-skin keeps that. What makes a strategy game its own is **the shape of a
match and the identity of a player**:

* the match has an **arc** (Eras: Dawn, Expansion, Conflict, Reckoning) that changes what matters;
* the player has **decisions that define them** (Doctrines: a draft at each era that bends the economy);
* the map has **places worth fighting for** (Landmarks: Mints, Garrisons; sharper in the last era);
* the long game has **a record** (Commander rank from play, cosmetic only);
* the screens show it with **their own structure** (a Dominion panel, a draft card, a war report), not RoWorld's;
* the **map itself looks like ours**: a war-room cartography style (inked borders, hatched territory,
  paper-toned land, banded sea) in place of RoWorld's flat vivid fills. This is the first thing a player sees
  and the thing a re-skin never touches, so it is its own phase, and the only visual work I can check with
  my own eyes offline (render to PNG, open the image).

Everything gameplay-side lives in the deterministic sim, behind a config flag that is OFF in `Sim.new`
and ON in Session / ServerMain, so the inherited 70+ tests keep proving the base is untouched.

## What I can and cannot verify (said up front)

* Verifiable offline: sim rules (Lune tests), protocol round trips, mirror parity, UI *construction* under
  the Lune fake Roblox runtime, syntax of every script, rojo build, contrast numbers.
* NOT verifiable offline: how anything looks or feels, phone layout, real network behaviour, whether the
  upstream's 271 asset ids load. Every phase ends with the offline gate; the Studio run stays one
  batched checklist at the end.

## Phase order (changed in round 4)

Cartography is built FIRST: it does not depend on the sim work, it is the one thing I can inspect with my own
eyes (render, then open the image), and it is what answers "not recoloured" on first launch. If the session
ended after one phase, the player would at least see a different game. Order: 1 Cartography, 2 Eras and
Doctrines (sim), 3 Dominion HUD and Doctrine UI, 4 Landmarks v2 and Edicts, 5 Career, 6 Title, report, docs.
(The phase headings below keep their original numbers for the audit log's sake; read them in this order.)

## Rules the code must follow (round 4)

* `Sim.new` defaults EVERY new flag to OFF, always. `Sim.DEFAULTS = { landmarks = true, doctrines = true }`
  holds only the values the shipped game turns on; `Session` and `ServerMain` apply it, and the new flag-on
  tests apply it. `Sim.new` never reads it, or every inherited exact-number test would silently run with the
  flags on.
* One helper per number: `self:_income_of(id)` and `self:_cap_of(id)`, called by BOTH `o_income` writers and
  BOTH `o_cap` writers. The landmark multiplier moves into them and is deleted from the gold-add line.
* `tests/landmarks.luau` is rewritten to assert snapshot income == gold earned per second (income refreshes
  on a staggered `(tick + id) % 10` schedule, so a gold ratio over a window is the wrong check).
* UI tests expose `Instance`, `Enum`, `Font`, ... through a per-test helper (`tests/helpers/ui_env.luau`),
  never through `tests/prelude.luau` (that could flip runtime-detection branches in the inherited tests).
* The layout test is a PARTIAL check and is named so: under Lune the insets are 0 and the top-left reserve is
  a fallback, so the real Roblox top bar is never measured.
* A player who spawns mid-era gets that era's offer with a FRESH deadline (never an instant auto-pick).
* Tests rewritten on purpose (not regressions; recorded in `memory/active-work.md` as they are): `tutorial`,
  `map2d_render`, `cosmetics`, `landmarks`.

## Pillars and phases

### Phase 1: Eras + Doctrines in the sim (server-authoritative)

* `Data/Eras.luau`: era boundaries in ticks from the start of play (`DEFAULT`: 0, 3:00, 9:00, 16:00),
  names, one-line purpose, `era_at(tick, playing_since, eras)`. The tutorial's match uses shorter ones so a
  new player meets their first draft in the first five minutes.
* `Data/Doctrines.luau`: 12 doctrines in 3 tiers (4 per tier pool, 3 offered each draft). Each is a set
  of multipliers on exactly these levers, all already inside `Sim._economy_tick` / landmark code:
  gold income, troop cap, landmark bonuses, conquest gold, trade/train payouts (no growth lever: round 3 showed `troop_growth` returns a capped delta and the command bar computes its growth label locally, so a multiplier there would be both wrong and untruthful). The real hook
  sites (grepped, round 2): income at the two `o_income` writers (`_start_playing`, `_economy_tick`); cap at
  the two `o_cap` writers (same two); conquest
  gold at `Sim` line ~1669; trade and train payouts at the single `SimState.add_bonus_gold`; landmarks in
  `SimLandmarks` itself. Several carry
  a trade-off, always paid in GOLD or a landmark bonus, never in cap (a lowered cap would delete troops in one tick: "+25% cap, -10% gold") so the choice means something.
* `Core/SimDoctrines.luau` (mixin like SimLandmarks): at each era start every living owner gets an offer
  of 3 chosen by a hash of (match seed, owner id, draft), no RNG draw, so the sim's random sequence and the
  upstream parity tests are untouched. Nations and bots pick by the same hash. A human who has not chosen
  in `DRAFT_TIMEOUT_S` (60) gets the first offer. Per-owner cached multipliers; `Sim` reads them with
  one `if self.doctrines_on` branch.
* Intent `doctrine` (append to `Protocol.INTENT_TYPES`, key travels in the existing `kind` string).
* Mirror: `Ev.DOCTRINE` (new id 35: owner, draft, a, b, c, chosen) plus `doctrine` + `eras` keys in the
  snapshot for late joiners; `GameState` keeps `doctrine[owner]` and fires a signal.
* Tests: pure data (tiers, no unknown levers, every offer distinct, trade-offs net positive but not
  dominant), sim (offer at era start, choose, timeout auto-pick, multipliers move gold/cap/growth by the
  stated amounts, off-by-default leaves upstream numbers identical), protocol round trip of the intent and
  event, mirror receives the event and a snapshot, determinism (same seed, same offers).
* Gate: whole existing suite green + new tests.

### Phase 2: Cartography (the map's own look; verified by rendered images)

* `MapSurface.terrain_pixel` / `tile_pixel` are pure per-tile functions. Redo them: sea in banded depth
  tones with a pale shoreline halo, land in paper tones with a slope shade from the terrain magnitude,
  territory in the owner's colour with a diagonal hatch (period and angle fixed, so repaint is stable and
  cheap: the pattern is a function of x, y only), borders inked (owner colour darkened hard) one pixel wide.
* A Lune tool renders a real match state (the default map, a seeded sim run for some ticks) through the
  same pure functions to a PNG which I open and judge, at map scale and at a zoomed crop, over at least
  three colour sets (including the two most similar owner colours) so borders and hatching are legible.
* Gates: `map2d_render` (the inherited colour assertions are updated to the new style, deliberately, each
  one rewritten with the reason), the repaint tests (`map_surface_repaint`) unchanged in behaviour, a new
  test that the hatch is a pure function of (x, y) and that two adjacent owners never produce the same
  pixel on their shared border.
* Perf guard: `tile_pixel` stays O(1) with no allocation (a micro test counts nothing allocated).

### Phase 3: Dominion HUD + Doctrine UI (new structures, not recolours)

* `UI/DominionPanel.luau`: the top-centre status becomes one panel with our own composition: the era
  timeline (4 segments, current filled, name, time to next era), the world-control bar and goal that
  `TopStatus` shows today, and my doctrine pips. It replaces `TopStatus`'s header row rather than stacking a
  second bar on it; placed from the measured HUD top row, never over the Tutorial card (a layout test
  asserts non-overlap at 844x390, 1280x720 and 1920x1080).
* `UI/DoctrineDraft.luau`: three cards (name, glyph, effect lines in plain numbers, trade-off line, hold-to-
  confirm not needed: one tap), a countdown ring for the auto-pick, opens when my offer exists, never dims
  or blocks the map (the match keeps running), dismissable to a "DRAFT" chip that reopens it.
* Era banners (existing `Banner`): "ERA II · EXPANSION" with its one line; feed lines (existing `Ev.MSG`)
  when someone drafts or captures a landmark.
* Tutorial: lesson "Eras and doctrines"; help overlay sections for Eras, Doctrines, Landmarks.
* Gate: the widgets are constructed and driven under the Lune fake runtime (no errors, correct visibility,
  sends the right intent); layout non-overlap test; syntax gate.

### Phase 4: Landmarks grow up, and Edicts (a new verb)

* Edicts: two of the three Reckoning doctrines grant one active order with a long cooldown: Empire of Coin
  gives a Windfall (60 s of income at once), Grand Army gives a Levy (20% of cap as troops). Wonder Keepers is
  passive. Anything that touches enemy territory is NOT included (too invasive for the inherited attack
  code). New intent `edict`, validated like `doctrine`, cooldown in the
  snapshot row. Cut first if the budget runs short.

* Capture / loss messages through `Ev.MSG` ("Red took the Mint at ..."), once per change of holder
  (throttled), tracked in `SimLandmarks`.
* Reckoning (era IV): landmark bonuses double, and the badge pulses; the era strip says so.
* Landmark strength scales with doctrine (Cartographers, Wonder Keepers).
* Tests: capture message once per change, doubling in era IV, doctrine interplay, off-flag silence.

### Phase 5: Commander record (cosmetic, local-trust)

* `Data/Career.luau`: pure rank ladder from XP (Recruit ... Marshal), XP from a finished match: time
  survived, land share, landmarks held, doctrines drafted, win bonus; diminishing for very short matches.
* Stored through the existing per-user settings section (`career`), shown on the title (replacing the
  "Commander" word) and on the game-over screen as "+XP, rank progress".
* Cosmetic only: no Stars, no crates, nothing sellable, so client-reported XP cannot be abused for value.
* Tests: ladder monotone, XP formula bounds, junk saved data is repaired, no negative XP.

### Phase 6: Title, report, docs, final gate

* Title: recompose around our identity (wordmark, rank line, last-match recap, the era/doctrine pitch as three short lines) instead of RoWorld's dock arrangement where it can be done with the existing widgets.
* Game over: add the doctrines taken and landmarks held to the existing summary rows.
* `docs/ASSETS_TODO.md`, `NOTICE.md`, README refreshed; memory notes; full `node tools/check.js` (not
  `--fast`) once; rebuild the place file.

## Out of scope on purpose

* Replacing the upstream art/audio/font ids (needs uploads only the owner can make; documented).
* New maps, new unit types, rebalancing the inherited war math (high risk, low evidence).
* Pay-to-win. No doctrine is sold; nothing here touches Products.

## Risks and mitigations

| risk | mitigation |
|---|---|
| New sim state desyncs mirror / breaks inherited tests | flag off by default; events + snapshot keys follow the REINFORCE pattern; run the whole suite each phase |
| Balance: one doctrine dominates | tests bound each doctrine's net value; tier pools offer 3 of 4 so no fixed best opener; numbers are one table |
| Unverifiable UI breaks at runtime | build every new widget under the fake runtime in tests; `pcall`-guarded layer registration already exists for map layers; syntax gate |
| HUD overlap on phones | layout test with explicit rects; EraStrip sits in the measured top row |
| Draft interrupts combat | non-modal card, 60 s auto-pick, chip to reopen |
| Context loss mid-build | each phase ends green and is written to `memory/active-work.md` |

## Audit log

### Round 1 (self, against the code)

Checked each assumption in the code before trusting it. Findings, all folded into the phases above:

1. **Truthful numbers.** The HUD shows `o_income + o_bonus_rate` and `o_cap` from the snapshot. The landmark
   code I already shipped multiplied gold at the point of adding it, so the HUD income would not match
   what the player actually earns. Fix (Phase 1): apply gold / cap multipliers where `o_income` and
   `o_cap` are *set*, so every number on screen is the real one. `tests/landmarks.luau` gains a check that
   the snapshot's income row equals the rate actually earned.
2. **Who drafts.** Humans and nations only (not the up to 400 tribes: event spam, snapshot bloat, no
   flavour). The tutorial's match turns nation drafting off (config `doctrines_ai = false`) so a new player
   is not out-scaled while learning.
3. **Seed.** `Sim.new` keeps the seed only in a local; Phase 1 stores `self.seed` for the offer hash.
4. **UI is testable.** Verified: GlassPanel and the Widgets kit construct under Lune with the real
   `Instance` (probe run). So Phase 2's widgets get construction + behaviour tests, not just a syntax check.
5. **Intent path.** `MatchServer.intent` rate-limits and decodes by whitelist; `kind` is a string of at most
   16 characters, so doctrine keys are capped at 16 and a test asserts it.
6. **Eras are relative** to `playing_since`; a late joiner and a snapshot both carry `eras`, so the client
   never guesses.
7. **Scope honesty.** Phases 5 and 6 are optional polish; if the budget runs short they are cut, not rushed.
   Phases 1 to 4 are the product.

### Round 2 (advisor), and what changed

1. **Visual identity was not a pillar** (the user's last two messages were about the look; "not recoloured").
   Added Phase 2 (Cartography) and changed Phase 3 from "bolt on a strip" to a recomposed Dominion panel.
2. **Wire path verified, not assumed** (greps): snapshots and events are generic tagged values, so extra
   keys and a new event id travel; `MatchServer.is_private` filters only MSG and BONUS, so a DOCTRINE event
   is broadcast (fine: drafts are public knowledge); `GameState` ignores event ids with no handler, so an
   old client survives a new event. Phase 1's tests go through `Protocol.encode/decode` for the mirror and
   the late-joiner snapshot, never straight Sim-to-GameState.
3. **"All levers are in `_economy_tick`" was false**; hook sites are now listed above. Also folded in:
   grep every `o_income` / `o_cap` writer (done: four sites), re-run `tests/landmarks.luau` after moving the
   multiplier (its ratio check must move with it), negative-cap trade-offs (troops above a lowered cap must
   shrink sanely, never below zero; tested), iteration by owner index only (determinism), and run
   `sim_bench` / `simsys_perf` once after Phase 1 for the hot-loop branch.

### Round 3 (independent agent, code only), and what changed

Ten faults found; all accepted:

1. **Wire schema.** `Protocol.write_table` takes only dense arrays or string-keyed maps. So: snapshot
   `doctrine` is a dense array of rows `{owner, draft, a, b, c, chosen, deadline_tick}` with `0` for "none"
   and never a nil inside; the event is the same row. A hard Protocol round-trip test, plus a multiplayer-
   config `net_sim` run with doctrines on. (The solo path bypasses Protocol, so only the test catches this.)
2. **Nothing exercises the flag.** The inherited mirror/parity tests never turn it on. `Sim.DEFAULTS` (a
   table of the shipped flag values) is introduced; new test files run the mirror, late-snapshot and a
   `net_sim`-style match with `doctrines` and `landmarks` ON and compare both sides.
3. **No growth lever** (see Phase 1). No cap trade-offs.
4. **Map paint has two code paths.** `paint_queue` re-implements fill/border inline and only fallout, skins
   and out-of-range tiles use `tile_pixel`. Any style change goes into the palette build (`refresh_palette`)
   and the shared pure helpers so both paths stay pixel-identical, with a test comparing them tile by tile.
5. **Hatching aliases when zoomed out** (about 2.4 tiles per screen pixel at 844 px on the 2000-wide world).
   The PNG tool therefore resamples nearest at the real fit scale for 844x390 *and* shows a 1:1 crop. Hatch
   is adopted only if it survives that downscale; otherwise the style is wash + inked borders + banded sea,
   decided by looking at the images, not in advance.
6. **HUD.** `UIRoot` reads `TopStatus` in about 15 places and `Tutorial._place` hard-codes y. So: keep the
   `TopStatus` API and its compact one-line pill; the Dominion is a second element placed from
   `top:bottom_edge()`; `Tutorial._place` and the alert slot read that edge; in compact mode the Dominion is
   one short line (era name + pips). A Lune test constructs the real `UIRoot` pieces involved at the
   three viewports and asserts the rects do not overlap.
7. **Doctrine intent validation lives in `Sim`**: human owner, an open offer, the key is one of the three
   offered, no re-pick, first intent per tick only; `take_over` recomputes the taker's state.
8. **Late joiners.** Snapshot rows carry the open offer and its deadline; a joiner gets the current era's
   offer (no back-pay for earlier eras: stated, not hidden).
9. **Tests that will change deliberately**, each rewritten with its reason: `tutorial` (lesson count, funnel
   order, lesson keys), `map2d_render` (terrain RGB), `cosmetics` (`tile_pixel` literals), `landmarks`
   (moves with the multiplier). Map-picker thumbnails bake the old palette: listed in ASSETS_TODO.
10. **"Still RoWorld" omissions** accepted as out of reach offline (upstream art/audio, 271 asset ids,
    verbs). One gameplay verb is added instead of only numbers: **Edicts** (Phase 4): each era-III doctrine
    grants an active order (Phase 4).

## Progress

* Phase 1 Cartography: DONE (2026-10-31). MapSurface: `build_terrain` (relief shade from the north-west, isobath
  rings, inked coast), new palette, territory wash alpha 188, border darken 0.34. Judged from rendered PNGs
  (`node`-free: `lune run tools/map/render_map.luau europe 1500 7` then `python tools/map/rgba_to_png.py
  build/map_europe.rgba`): dark nautical sea with a pale halo, parchment land, inked borders. Hatching was NOT
  used (aliases at fit scale). `tests/map2d_render.luau` terrain assertions rewritten on purpose (exact old
  RGB literals replaced by style properties + `build_terrain` tests); `map_surface_repaint` unchanged, passes.
* Phase 2 Eras + Doctrines (sim): DONE. `Data/Eras`, `Data/Doctrines`, `Core/SimDoctrines` (mixin; one
  `_refresh_mults` computes landmark + doctrine multipliers once a second and on a pick; `_income_of` /
  `_cap_of` used by all four `o_income` / `o_cap` writers), `Ev.DOCTRINE` (35), intent `doctrine`,
  snapshot `eras` + `doctrine` rows, `GameState.doctrine` / `eras` / `doctrine_changed`, `Sim.DEFAULTS` (never
  read by `Sim.new`), Session/ServerMain apply it. Gate: `tests/doctrines.luau` (data, sim, timeout, wire
  through zstd Protocol deltas and a late-joiner snapshot, mirror parity of grid + caps), `tests/landmarks.luau`
  rewritten to assert shown income == earned income. `sim_bench` runs (flags off). Session/ServerMain read
  `Sim.DEFAULTS` defensively because `net_session` / `fix_server` inject a stub Sim.
* Phase 3 Dominion HUD + draft UI: DONE. `UI/DominionStrip` (pure `model` + a node owned by `TopStatus`: a second
  row on a desktop, a roman numeral in the phone pill; everything stacked under the status already clears
  it), `UI/DoctrineDraft` (non-modal three cards, Later -> DRAFT chip, countdown, sends the `doctrine`
  intent), era banners, tutorial lesson "eras", help sections (Eras & doctrines, Landmarks; the inherited
  "gold flows from your land" line was wrong and is corrected). Gate: `tests/ui_doctrine.luau` builds the real
  widgets under Lune (per-test env helper; Lune has no MouseEnter, so buttons are a stand-in there) incl. the
  844x390 fit; `TopStatus` itself cannot be built under Lune (InputBegan), so its integration is checked by
  reading + luau-lsp only: say so in the Studio checklist.
* Phase 4 Landmarks v2 + Edicts: DONE. Capture news (once per change, only when a person is involved), the
  Reckoning doubling (sim) and badge breathing (client), Edicts `windfall` / `levy` (intent `edict`, `Ev.EDICT`
  36, snapshot `edict` rows, one shared cooldown of 3:00, chips in the draft widget). Tests added to
  `tests/doctrines.luau`.
* Phase 5 Career: DONE (`Data/Career`, `tests/career.luau`; XP is cosmetic and local-trust; awarded in
  `UIRoot._award_career`, shown as a feed line and in the title greeting). The tutorial match now passes
  `Eras.TUTORIAL` and `doctrines_ai = false` through `Session.start_solo`.
* Phase 6: README, ASSETS_TODO and PLAN updated. NOT done, on purpose: recomposing the title screen layout
  (it keeps the inherited arrangement; only the wordmark, rank greeting and credits are ours) and a
  war-report addition to the game-over screen (the career line goes to the feed instead): both are
  unverifiable offline and the existing screens are the safer base.
* Final gate (2026-10-31): `node tools/check.js` (full, with benchmarks): 81 Lune files, syntax of every
  script, rojo build: all pass. `build/ConquerTheWorld.rbxl` rebuilt.

### Round 5 (advisor, before reporting), and what changed

1. The Tutorial card and the toast stack sat at y values tuned to the old one-row status pill; both now start
   below `top:bottom_edge()` on a desktop (`Tutorial._place`, `UIRoot._layout`). Coach already avoids the panel
   through its blockers.
2. The draft can no longer cover the command bar: it folds to the DRAFT chip when its cards do not fit the
   free band, and stays folded while the tutorial has not reached its "eras" lesson; the tutorial's drafts get
   150 s instead of 60 (`draft_timeout_s`). Tests added (phone band, tutorial states).
3. The timeline fill uses the kit's `set_anchors` / `set_offsets` (they queue layout).
4. Era openings picked for every nation and refreshed the multipliers each time; now once per opening.
   Measured with both systems on, the World map, 400 tribes, Lune (non-native): era boundary ticks 43 / 6 /
   10 ms against a 20 ms average there.

---

# Round 2 of the plan: "everything players see is ours" (2026-10-31)

Request: base stays RoWorld; every player-facing asset becomes ours. Findings that shape it:

* ~271 `rbxassetid` ids in `src/shared/Assets/*` belong to the upstream's Roblox account (UI icons, structure
  and unit sprites, status icons, panel shadows, flags, crate / arsenal art, ~100 sounds, music, one font).
  There is no Open Cloud key on this machine (`.secrets/roblox_api_key` absent), so nothing can be uploaded
  by me; and an id we do not own may not load in our experience at all.
* What needs no upload: **EditableImage** (the map already depends on it) and **built-in fonts**
  (Studio ships Montserrat with weights 100 to 900, and fontTools can read its advances for the kit's
  metric tables). References: the EditableImage docs
  (<https://robloxapi.github.io/ref/class/EditableImage.html>) and the DevForum guide
  (<https://devforum.roblox.com/t/a-complete-guide-to-editableimages/3858566>) for `WritePixelsBuffer`;
  Lucide's Roblox ports (<https://github.com/VirtualButFake/lucide-roblox>) show icon-set plumbing but are
  third-party art, so they are not used: the icons are drawn here.
* Everything drawn here can be checked here: a pure-Luau rasteriser runs under Lune, renders to PNG, and I
  open the PNG.

Phases (each ends with the offline gate and a rendered contact sheet where there is art):

A. **Font**: Montserrat via `rbxasset://fonts/families/Montserrat.json`; the metric tables regenerated from the
   TTFs (400, 500, 700, 900; 600 and 800 interpolated); line-height constants from its hhea; the 24 hard-coded
   `Font.fromId(...)` sites go through `UITheme.font`.
B. **Raster engine** (`src/shared/Art/Raster.luau`: signed-distance shapes, analytic anti-aliasing, add / erase,
   one buffer out) and **our icon set** (`Art/Icons.luau`: every `UITheme.icon` name, drawn on a 64 grid as
   white masks) with a runtime atlas (`Art/Atlas.luau`); consumers (`Widgets.Icon`, `UICtx.make`, ~20 direct
   `.Image =` sites) go through one helper that takes either a string id or an art reference.
C. **Map art**: structure plates and glyphs, unit sprites, status icons, panel shadows (9-slice), shapes.
D. **Everything else visual**: flags (our own heraldic emblems from a hash of the nation's name), crate /
   arsenal / rail / fx art where it can be drawn; where it cannot, the feature shows a plain drawn stand-in,
   never a blank.
E. **Audio**: only ids the owner uploaded (the six SFX and two tracks from the earlier project) are kept; the
   rest of the upstream ids are removed so every missing sound is a silent skip by the existing contract.
   Credits lose "Music by" once no upstream track is used (the OpenFront copyright stays).
F. **Guard**: `tools/check.js` fails on any `rbxassetid://<n>` in `src` that is not in
   `docs/OWNED_ASSETS.txt`, so "entirely ours" is enforced, not claimed.

Risks: the runtime art costs startup time (build sliced over frames, cached per session) and EditableImage
memory (one small atlas per family); an unseen layout shift from the wider font (the kit's boxes are
metric-driven, so they follow the tables); sound is the one family that stays thin until the owner uploads
more. The Studio checklist grows by: icons, sprites, shadows, font, flags.

# Round 3 of the plan: release + 10 updates of content (2026-10-31)

Request: "release state and 10 updates worth of content"; come back only when final. Every update = sim or data change,
a UI surface, help text, a Lune test, a Studio check; snapshot `build/snap/` first; `check.js --fast` after each.
Sim rules: flag off in `Sim.new`, on via `Sim.DEFAULTS`; no sim RNG draws (hash like `Doctrines.mix`); rows-only wire; new
`Ev` ids appended; snapshot nil when off; flag-on mirror test. Anything paying Stars/items goes through server sanitize; client-reported
progress (Career, Orders, Medals, Season) stays cosmetic.

Release polish first: log prefixes, title recomposition (Modes / Commander), Starter + thumbs check, Reckoning harness (`god` debug).
1. Doctrines II + Edicts II: pool 12 -> 24; levers atk/def/regen/build; every tier-3 doctrine has an edict.
2. Landmarks II: Citadel, Harbor, Granary, Foundry; drawn badges.
3. World Events: scheduled by hash each era; banner, HUD chip, news.
4. Rivals: nation personalities, doctrine preference, taunts, nemesis.
5. Game modes: Blitz, Crown (hold to win), Treasury; solo mode picker.
6. Maps: six fictional maps from our own generator.
7. Field Orders: daily and weekly goals, paying Merit (cosmetic).
8. Medals + Commander Record: 48 medals, 20 ranks with insignia, titles, profile screen.
9. War Room campaign: 24 missions, 3-star ratings, unlock chain.
10. War Report + Season One: end-of-match timeline and highlights; merit track; cosmetic batch.

Only the owner can do (final checklist, not stops): publish source + SOURCE_REPO (AGPL 13), audio upload key, developer products,
EditableImage permission + creator verification on the published place, store art, a real phone test.

## Round 3 progress (2026-10-31)

All ten updates are built, tested offline and seen in Studio except where noted below. `tests/progress.luau`, `modes.luau`, `maps_invented.luau`,
`soak_modes.luau` and additions to `doctrines.luau`, `landmarks.luau`, `ui_doctrine.luau` cover them. Found by running it and fixed: the Crown could be
won by whoever spawned on it (now opens at 5 minutes), the results screen washed the map white, the map's edge was grey, phone title and results rows overflowed.
Not done on purpose: the title and HUD arrangement stays RoWorld's; real audio needs the owner's say-so and upload (docs/RELEASE_CHECKLIST.md).
