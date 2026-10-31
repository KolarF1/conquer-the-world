--!strict
-- Art made on demand. Shared data modules (Data/Cosmetics) cannot make an image; they hand out a descriptor
-- { art = true, kind = "flag", ... }, and the client registers a resolver for the kind (UI/FlagArt), which turns
-- the descriptor into an ArtRef the first time an ImageLabel needs it. `resolve` returns what it is given for
-- anything that is already a plain ref or a string.
local Registry = {}

local resolvers: { [string]: (any) -> any } = {}

function Registry.register(kind: string, fn: (any) -> any)
	resolvers[kind] = fn
end

function Registry.resolve(ref: any): any
	if type(ref) == "table" and ref.art == true and ref.kind ~= nil and ref.content == nil then
		local fn = resolvers[ref.kind]
		if fn ~= nil then
			return fn(ref)
		end
	end
	return ref
end

return Registry
