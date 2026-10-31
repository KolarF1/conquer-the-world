-- The cosmetic crate's 3D chest (UI/ChestView, CrateOpening): ours, built at run time from plain Parts (no meshes, no
-- textures, no asset ids) inside a ViewportFrame. A wooden bottom, a lid, gold bands and a lock plate.
--   pivot at the bottom centre, front = -Z, lid closed; `hinge` = the lid's hinge point (the lid opens with a positive
--   rotation about X there); sizes in studs. The lid flips back `lid_open` degrees so it stays low.
-- Part fields: size (studs), cf = { x, y, z, r00..r22 }, color {r,g,b}, material, lid (moves with the lid).
return {
	size = { 5, 4.6666, 5 },
	hinge = { 0, 1.6667, 2.5 },
	-- the open chest's mouth (the card comes out here) and the lid's front seam (light leaks there)
	mouth = { 0, 2.1, 0 },
	seam = { 0, 1.6667, -2.5 },
	lid_open = 140,
	parts = {
		{ name = "Bottom", lid = false, size = { 4.6666, 2.3333, 4.6666 }, cf = { 0, 1.1667, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1 }, color = { 112, 74, 44 }, material = "Wood" },
		{ name = "Lid", lid = true, size = { 5, 3, 5 }, cf = { 0, 3.1666, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1 }, color = { 132, 88, 52 }, material = "Wood" },
		{ name = "BottomBandL", lid = false, size = { 0.5, 2.4, 4.9 }, cf = { -1.5, 1.1667, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1 }, color = { 226, 176, 72 }, material = "Metal" },
		{ name = "BottomBandR", lid = false, size = { 0.5, 2.4, 4.9 }, cf = { 1.5, 1.1667, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1 }, color = { 226, 176, 72 }, material = "Metal" },
		{ name = "LidBandL", lid = true, size = { 0.5, 3.1, 5.2 }, cf = { -1.5, 3.1666, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1 }, color = { 226, 176, 72 }, material = "Metal" },
		{ name = "LidBandR", lid = true, size = { 0.5, 3.1, 5.2 }, cf = { 1.5, 3.1666, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1 }, color = { 226, 176, 72 }, material = "Metal" },
		{ name = "Lock", lid = true, size = { 0.9, 1.1, 0.35 }, cf = { 0, 2.35, -2.55, 1, 0, 0, 0, 1, 0, 0, 0, 1 }, color = { 244, 208, 110 }, material = "Metal" },
	},
}
