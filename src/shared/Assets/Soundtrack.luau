-- The soundtrack: the two tracks the owner uploaded for this game, played in the moods the playlist asks for.
-- (The upstream's pack, Rodrigo Flores' Orchestral Ambients, is no longer used, so its credit is gone too.)
-- generated; see tools/assets/make_our_audio.py
return {
	credit = "",
	license = "",
	tracks = {
		lobby = { id = "rbxassetid://119425620491833", length = 180.0, title = "Lobby", pack = "Conquer the World" },
		battle = { id = "rbxassetid://73509293262264", length = 240.0, title = "Battle", pack = "Conquer the World" },
	},
	moods = {
		title = { "lobby" },
		wait = { "lobby" },
		calm = { "lobby" },
		war = { "battle" },
		victory = { "lobby" },
		defeat = { "lobby" },
	},
}
