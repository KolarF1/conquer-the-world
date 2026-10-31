-- Audio keys -> OUR sounds. Only ids the owner uploaded for this game are used (the six SFX and two tracks of
-- legacy/conquest/docs/UPLOAD_ASSETS.md); a key with no good match is left out, and the director skips a missing key
-- (silent, never someone else's sound). More sounds: add the file to assets/audio, upload it (tools/assets/upload_ours.py
-- when a key is in .secrets/roblox_api_key), and add its id to docs/OWNED_ASSETS.txt and to RULES in this file's generator.
-- (generated; see tools/assets/make_our_audio.py)
return {
	sfx = {
		card_flip = { id = "rbxassetid://137499164850957", length = 0.5 },
		card_whoosh = { id = "rbxassetid://137499164850957", length = 0.5 },
		countdown_gamestart = { id = "rbxassetid://126284092426471", length = 2.0 },
		countdown_tick = { id = "rbxassetid://137499164850957", length = 0.5 },
		countdown_tick_1 = { id = "rbxassetid://137499164850957", length = 0.5 },
		countdown_tick_2 = { id = "rbxassetid://137499164850957", length = 0.5 },
		countdown_tick_3 = { id = "rbxassetid://137499164850957", length = 0.5 },
		countdown_tick_4 = { id = "rbxassetid://137499164850957", length = 0.5 },
		countdown_tick_5 = { id = "rbxassetid://137499164850957", length = 0.5 },
		crate_drop = { id = "rbxassetid://122548385802638", length = 1.2 },
		crate_land = { id = "rbxassetid://122548385802638", length = 1.2 },
		crate_open = { id = "rbxassetid://122548385802638", length = 1.2 },
		crate_preview_common = { id = "rbxassetid://90458037613275", length = 1.0 },
		crate_preview_epic = { id = "rbxassetid://133770403709310", length = 3.0 },
		crate_preview_legendary = { id = "rbxassetid://133770403709310", length = 3.0 },
		crate_preview_rare = { id = "rbxassetid://90458037613275", length = 1.0 },
		crate_rattle = { id = "rbxassetid://137499164850957", length = 0.5 },
		crate_shimmer = { id = "rbxassetid://90458037613275", length = 1.0 },
		game_start = { id = "rbxassetid://126284092426471", length = 2.0 },
		queue_start = { id = "rbxassetid://90458037613275", length = 1.0 },
		reveal_common = { id = "rbxassetid://90458037613275", length = 1.0 },
		reveal_epic = { id = "rbxassetid://133770403709310", length = 3.0 },
		reveal_legendary = { id = "rbxassetid://133770403709310", length = 3.0 },
		reveal_rare = { id = "rbxassetid://90458037613275", length = 1.0 },
		spawn_confirm = { id = "rbxassetid://122548385802638", length = 1.2 },
		spectate_switch = { id = "rbxassetid://137499164850957", length = 0.5 },
	},
}
