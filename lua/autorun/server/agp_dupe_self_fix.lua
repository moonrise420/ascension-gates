--[[
	Ascension Gates (2026-11-08): GMod's duplicator copies an entity's whole Lua table, its self-reference "Entity"
	(self.Entity, which nearly all CAP code uses) included, and merges that table into the pasted copy. In the same
	session the copy's self.Entity then pointed at the ORIGINAL: a pasted display drained the original ship's energy,
	and code on the copy that used self.Entity acted on the original (found by the PowerGrid dupe test). The copy
	keeps its own self.Entity: the self-reference is left out of the copied data.
]]
if (not duplicator or not duplicator.CopyEntTable or duplicator.AGPSelfFix) then return end
duplicator.AGPSelfFix = true

local copyEntTable = duplicator.CopyEntTable
duplicator.CopyEntTable = function(ent, ...)
	local data = copyEntTable(ent, ...)
	if (istable(data) and data.Entity ~= nil) then data.Entity = nil end
	return data
end
