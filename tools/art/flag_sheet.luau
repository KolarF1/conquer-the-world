--!nonstrict
-- Renders a sample of our flags into build/art_flags.rgba (u32 w, u32 h, RGBA) for tools/art/rgba_to_png.py (the
-- map one works: tools/map/rgba_to_png.py). Run: lune run tools/art/flag_sheet.luau
local fs = require("@lune/fs")
local Emblem = require("../../src/shared/Art/Emblem")
local keys = {
	{ "ad" }, { "ae" }, { "af" }, { "ag" }, { "al" }, { "am" }, { "ao" }, { "ar" }, { "at" }, { "au" },
	{ "br" }, { "ca" }, { "cn" }, { "de" }, { "eg" }, { "es" }, { "fr" }, { "gb" }, { "in" }, { "jp" },
	{ "pumpkin_king", "Halloween" }, { "lion_crest", "Empires" }, { "radioactive", "Doomsday" }, { "kraken", "Naval" }, { "astronaut", "Space" },
	{ "dragon_dynasty", "Empires" }, { "warhead", "Doomsday" }, { "lighthouse", "Naval" }, { "comet", "Space" }, { "bat_moon", "Halloween" },
}
local W, H = Emblem.W, Emblem.H
local cols = 5
local rows = math.ceil(#keys / cols)
local sw, sh = cols * (W + 8) + 8, rows * (H + 8) + 8
local sheet = buffer.create(sw * sh * 4)
buffer.fill(sheet, 0, 0x1C)
for i, k in keys do
	local px = Emblem.pixels(k[1], W, H, k[2])
	local x0, y0 = 8 + ((i - 1) % cols) * (W + 8), 8 + ((i - 1) // cols) * (H + 8)
	for y = 0, H - 1 do
		for x = 0, W - 1 do
			buffer.writeu32(sheet, ((y0 + y) * sw + x0 + x) * 4, buffer.readu32(px, (y * W + x) * 4))
		end
	end
end
local head = buffer.create(8)
buffer.writeu32(head, 0, sw)
buffer.writeu32(head, 4, sh)
fs.writeFile("build/art_flags.rgba", buffer.tostring(head) .. buffer.tostring(sheet))
print("flags", sw, sh)
