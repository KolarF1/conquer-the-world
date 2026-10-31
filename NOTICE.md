# Notice

**Conquer the World** is a modified version of **RoWorld** (by Snick Co.,
<https://github.com/lukechatton/roworld>), which is itself a modified version of **OpenFront**.

- © OpenFront and Contributors.
- Changes © 2026 Snick Co. (RoWorld).
- Changes © 2026 the Conquer the World developers.

This program is free software: you can redistribute it and/or modify it under the terms of the
**GNU Affero General Public License, version 3**, with the additional terms (AGPL section 7) in the
[LICENSE](LICENSE) file:

1. **Copyright preservation (7(b))**: the notice "© OpenFront and Contributors" must stay visible in
   the game (title screen footer and the Help & Credits window). `tools/check.js` verifies it.
2. **No misrepresentation (7(c))**: this is not OpenFront, is not RoWorld, and is not endorsed by
   either. Do not use "OpenFront" as the title or imply official endorsement.

It comes with ABSOLUTELY NO WARRANTY.

## What this means for you (the publisher)

- **Source must be offered** to everyone who uses the game (AGPL section 13): publish this
  repository's *modified* source publicly and put its GitHub path in
  `HelpOverlay.SOURCE_REPO` (src/client/UI/HelpOverlay.luau). Until you do, the game is not
  compliant. Any further changes you make must be published under the same licence.
- Selling things in the game (Robux items) is allowed; the licence only requires the source stays
  available and the notices stay in place.
- Anything copied from this tree (code, and the art and audio in `assets/`) is under the AGPL as
  part of the Program unless a file says otherwise. Third-party material keeps its own terms:
  maps (Natural Earth, NOAA ETOPO1) are public domain. The upstream's flags (Wikimedia Commons) and music (Rodrigo Flores) are
  no longer used: the flags are our own emblems and the tracks are ours (`src/shared/Assets/Soundtrack.luau`).

## Assets from the upstream experience

The code references Roblox asset ids (`rbxassetid://...`) that were uploaded by the upstream
creator's account. They may stop working or be withdrawn at any time. The original art and audio
files are in `assets/`; upload your own copies and replace the ids (see docs/ASSETS_TODO.md).
All upstream product, subscription and branding ids have been removed from this fork (set to 0 /
empty) so that nothing is sold under the upstream's identity.
