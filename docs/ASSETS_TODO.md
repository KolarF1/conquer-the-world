# Assets: what is ours, and what is still thin

As of 2026-10-31 nothing the player sees is an asset id from the upstream's account. `node tools/check.js` fails on any
`rbxassetid://` in `src` that is not listed in `docs/OWNED_ASSETS.txt`, on `Font.fromId`, and on ids built at run time.

## Ours, drawn here and shipped as data or made on the device
| what | how | where |
|---|---|---|
| UI glyphs (55) | shape lists, rasterised by `tools/art`, packed, decoded into one EditableImage atlas | `tools/art/icons.luau`, `src/shared/Art/IconData.luau`, `UI/ArtAtlas.luau` |
| structure plates, glyphs, 12 unit sprites | same | `tools/art/mapart.luau`, `Art/MapData.luau`, `Map/MapArt.luau` |
| map effects (explosion, flag, banner, SAM, dust, fire, smoke) and rail tiles | palette-index frames | `tools/art/fx.luau`, `Art/FxData.luau`, `Map/MapFxArt.luau` |
| invented maps (6) | layered noise and a shape per map, no outside data | `tools/maps/make_fictional.py`, `server/MapData/*` |
| map thumbnails | the maps' own terrain bytes, coloured with the in-game palette | `tools/art/thumbs.luau`, `Art/Thumbs/*`, `UI/ThumbArt.luau` |
| flags (258 + the shop's) | heraldic emblems from a hash of the key | `Art/Emblem.luau`, `UI/FlagArt.luau` |
| panel shadows, vignette, glows, radial menu sectors, spinner, crate light | generated at run time, a few ms each | `UI/SoftArt.luau` |
| the chest | plain Parts | `Assets/CrateModel.luau`, `UI/ChestView.luau` |
| the map itself | chart style (relief, isobaths, inked coast) | `Map/MapSurface.luau` `build_terrain` |
| font | Montserrat (ships with Roblox); metrics and kerning from its TTFs | `tools/art/make_font_*.py`, `UITheme.luau`, `UIKern.luau` |
| sound | only the six SFX and two tracks the owner uploaded (`docs/OWNED_ASSETS.txt`) | `Assets/Audio*.luau`, `Soundtrack.luau` |

Re-render and look: `lune run tools/art/contact.luau`, `tools/art/mapart.luau`, `tools/art/fx.luau`,
`tools/art/flag_sheet.luau`, `tools/art/soft_sheet.luau`, then `python tools/art/mask_to_png.py build/<sheet>.mask`.

## Still thin (said plainly)
* **Sound.** 24 of 29 core SFX keys, all the UI and crate ones, and a single lobby and battle track play; combat sounds
  (shells, SAMs, nukes, ships) are the owner's six sounds at other speeds (`AudioDirector.BASE_SPEED`). Make more with the ElevenLabs connector, upload to the owner's account,
  add the ids to `docs/OWNED_ASSETS.txt` and to `tools/assets/make_our_audio.py`. Audio uploaded by a user only plays in
  experiences that account owns or has granted: publish under the same account.
* **Arsenal item previews** (animated demos) are off; the cards show the item glyph large.
* **Experience icon and thumbnail** (Creator Hub) are not in the code: `legacy/conquest/assets/images` has candidates.
* **EditableImage** must be allowed for the experience (Game Settings > Security, and the creator verified), or the map and
  all of the art above are blank. It is the one thing the whole look depends on: check it first in Studio.
* **Product ids** are 0 (hidden) until real developer products are made.
