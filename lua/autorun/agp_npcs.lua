--[[
	Ascension Gates: the Tau'ri as NPCs (2026-11-10, the owner's idea). The four groups stand on CAP's SG soldier in
	each group's cloth (2026-11-12; notes/models/agp_cap_soldier_build.py), which carries the HL2 citizens' NPC
	animations next to the player's: they are citizens (allies of the players, they follow on "use"). One entry per
	group in the Stargate tab, NPCs. They do not speak HL2's lines.
	(Our own Jaffa, Serpent Guard, Horus Guard, Goa'uld and Wraith groups stood on our own player models; they are
	parked with them for a later update - Code/parked/player_models_2026-11-12. CAP's own Wraith, Prior and Goa'uld
	NPCs are untouched.)
]]
local P2 = "models/player/agp_cap/"      -- CAP's SG soldier in our cloth

local ALLY = { citizentype = "4" }                                  -- CT_UNIQUE: keeps our model

-- a group's models: CAP's soldier in the group's cloth, and the same with a woman's head (three faces)
local function soldiers(key)
	local t = { P2 .. "cap_soldier_" .. key .. ".mdl" }
	for i = 1, 3 do t[#t + 1] = P2 .. "cap_soldier_" .. key .. "_f" .. i .. ".mdl" end
	return t
end

-- key, name, class, models, weapon, health, keyvalues, skins (a random one of 0 .. skins-1; Atlantis: the flag)
AGP_NPCS = {
	{ "agp_npc_sg", "SG Team", "npc_citizen", soldiers("sg"), "fnp90", 100, ALLY, 1 },
	{ "agp_npc_sgc", "SGC Personnel", "npc_citizen", soldiers("sgc"), "fnp90", 100, ALLY, 1 },
	{ "agp_npc_atl", "Atlantis Expedition", "npc_citizen", soldiers("atl"), "fnp90", 100, ALLY, 2 },
	{ "agp_npc_dst", "Destiny Crew", "npc_citizen", soldiers("dst"), "fnp90", 100, ALLY, 1 },
}

-- where an NPC's shot leaves its weapon: CAP's energy weapons started it at the NPC's eyes (the shooter's view for a
-- player), so a Jaffa's staff blast came out of his head, a staff length behind the staff's head (owner 2026-11-10).
-- An NPC firing points its weapon at the target: the muzzle is the right hand plus the weapon's reach along the aim
-- (staff ~50, Wraith stunner ~20, Zat ~8), never through a wall in front of it.
if (SERVER) then
	AGP = AGP or {}
	function AGP.NPCMuzzle(npc, reach, weapon)
		local b = npc:LookupBone("ValveBiped.Bip01_R_Hand")
		local hand = b and npc:GetBonePosition(b)
		if (not hand) then return npc:GetShootPos() end
		local aim = npc:GetAimVector()
		local tr = util.TraceLine({ start = hand, endpos = hand + aim * reach, filter = { npc, weapon }, mask = MASK_SHOT })
		return tr.Hit and (tr.HitPos - aim * 2) or tr.HitPos
	end
end

if (StarGate and StarGate.CheckModule and not StarGate.CheckModule("npc")) then return end

for _, n in ipairs(AGP_NPCS) do
	list.Set("CAP.NPC", n[1], {
		Name = n[2], Class = n[3], Model = n[4], Weapons = { n[5] }, KeyValues = n[7],
		Category = "NPCs", Author = "Ascension Gates",
	})
end

if (CLIENT) then return end

-- three sides like in the series (owner 2026-11-10): the Tau'ri, the Goa'uld with their Jaffa and guards, and the
-- Wraith, who are everyone's enemy. (Underneath the Goa'uld's people and the Wraith are all Combine soldiers, which
-- would make them allies: each pair of our NPCs is told whom to like and whom to hate.)
local SIDE = {
	agp_npc_sg = "tauri", agp_npc_sgc = "tauri", agp_npc_atl = "tauri", agp_npc_dst = "tauri",
	agp_npc_jaf = "goauld", agp_npc_srp = "goauld", agp_npc_hor = "goauld", agp_npc_gou = "goauld",
	agp_npc_wra = "wraith",
}
AGP_NPC_SIDE = SIDE

local function relate(a, b)
	local sa, sb = SIDE[a.AGPNPC], SIDE[b.AGPNPC]
	if (not sa or not sb) then return end
	local d = (sa == sb) and D_LI or D_HT
	a:AddEntityRelationship(b, d, 90)
	b:AddEntityRelationship(a, d, 90)
end

-- after the spawn: health, a skin (team number, uniform colour, department), and where it came from (agp_npc_voices)
hook.Add("PlayerSpawnedNPC", "AGP.OurNPCs", function(ply, npc)
	if (not IsValid(npc)) then return end
	local mdl = string.lower(npc:GetModel() or "")
	if (mdl:sub(1, #P2) ~= P2) then return end
	for _, n in ipairs(AGP_NPCS) do
		if (table.HasValue(n[4], mdl)) then
			npc.AGPNPC = n[1]
			npc:SetMaxHealth(n[6]); npc:SetHealth(n[6])
			if (n[8] > 1) then npc:SetSkin(math.random(0, n[8] - 1)) end
			for _, o in ipairs(ents.FindByClass("npc_*")) do
				if (o ~= npc and IsValid(o) and o.AGPNPC) then relate(npc, o) end
			end
			return
		end
	end
end)
