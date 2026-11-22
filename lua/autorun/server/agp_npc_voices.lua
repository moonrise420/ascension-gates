-- The Wraith, Prior and Goa'uld NPCs are Metro Police underneath, so they talked like Combine police (radio
-- chatter, "move along", the radio report when one dies). Most of that speech are engine sentences, which never
-- pass EntityEmitSound, so they are silenced at the source: the NPC is gagged (no idle talk), its "last sound"
-- is kept in the future with a high priority (CAI_BaseNPC::FOkToMakeSound refuses every normal sentence then),
-- and the pain and death sentences, which skip that check, are stopped right after they start.
-- The Wraith gets an eerie screech for pain and death instead; the Goa'uld and the Prior stay silent.
-- Our own NPCs (lua/autorun/agp_npcs.lua) - citizens on CAP's soldier in our cloth - get the same
-- treatment: no HL2 lines (no "Gordon", no Combine radio), only a human cry of pain (a woman's for the women) or, for
-- the Wraith, the screech.

local VOICE = {
	["models/pg_props/pg_charaktere/pg_wraith_test.mdl"] = "wraith",
	["models/tiny/playermodels/prior_pm.mdl"] = "prior",
	["models/viktork/player/anubis.mdl"] = "goauld",
}

local SOUNDS = {
	wraith = { pain = "npc/stalker/go_alert2a.wav", die = "npc/stalker/go_alert2.wav", pitch = 115 },
	man = { pain = { "vo/npc/male01/pain01.wav", "vo/npc/male01/pain03.wav", "vo/npc/male01/pain05.wav", "vo/npc/male01/pain08.wav" },
		die = { "vo/npc/male01/pain07.wav", "vo/npc/male01/pain09.wav" }, pitch = 100 },
	woman = { pain = { "vo/npc/female01/pain01.wav", "vo/npc/female01/pain03.wav", "vo/npc/female01/pain05.wav", "vo/npc/female01/pain08.wav" },
		die = { "vo/npc/female01/pain07.wav", "vo/npc/female01/pain09.wav" }, pitch = 100 },
}

local SF_NPC_GAG = 2
local tracked = {}
local crying = false

local function kindOf(e)
	if (not IsValid(e)) then return nil end
	local cls, mdl = e:GetClass(), string.lower(e:GetModel() or "")
	if (cls == "npc_metropolice") then return VOICE[mdl] end
	if (cls == "npc_citizen" and mdl:sub(1, 22) == "models/player/agp_cap/") then return mdl:match("_f%d%.mdl$") and "woman" or "man" end   -- CAP's soldier in our cloth, or with a woman's head (agp_npcs.lua)
end

local function hush(e)
	e:SetSaveValue("m_flSoundWaitTime", CurTime() + 5)
	e:SetSaveValue("m_nSoundPriority", 100)
end

hook.Add("OnEntityCreated", "AGP.NPCVoices", function(e)
	-- the model is set after creation (spawn menu / CAP.NPC list)
	timer.Simple(0, function()
		local kind = kindOf(e)
		if (not kind) then return end
		e:SetKeyValue("spawnflags", bit.bor(e:GetSpawnFlags(), SF_NPC_GAG))
		hush(e)
		tracked[e] = kind
	end)
end)

timer.Create("AGP.NPCVoices", 1, 0, function()
	for e in pairs(tracked) do
		if (IsValid(e)) then hush(e) else tracked[e] = nil end
	end
end)

-- what still gets through EmitSound (pain/death sounds, radio clicks): drop it
hook.Add("EntityEmitSound", "AGP.NPCVoices", function(t)
	if (not tracked[t.Entity]) then return end
	if (crying) then return end
	local name = string.lower(t.SoundName or ""):gsub("\\", "/")
	if (name:sub(1, 1) == "!" or name:find("metropolice", 1, true) or name:find("npc/overwatch/", 1, true)
		or name:find("vo/", 1, true) or name:find("combine_soldier/pain", 1, true) or name:find("combine_soldier/die", 1, true)) then
		return false
	end
end)

local function cry(e, which)
	local s = SOUNDS[tracked[e] or ""]
	if (not s) then return end
	local snd = s[which]
	if (istable(snd)) then snd = snd[math.random(#snd)] end
	crying = true      -- our own cry passes the filter below
	e:EmitSound(snd, 80, s.pitch + math.random(-5, 5), 1, CHAN_AUTO)
	crying = false
end

hook.Add("PostEntityTakeDamage", "AGP.NPCVoices", function(e, dmg, took)
	if (not tracked[e] or not took or e:Health() <= 0) then return end
	e:SentenceStop()
	if ((e.AGPNextCry or 0) < CurTime()) then
		e.AGPNextCry = CurTime() + 1.5
		cry(e, "pain")
	end
end)

hook.Add("OnNPCKilled", "AGP.NPCVoices", function(e)
	if (not tracked[e]) then return end
	e:SentenceStop()
	cry(e, "die")
	tracked[e] = nil
	-- the death sentence may start after this hook: stop it again a moment later
	timer.Simple(0, function() if (IsValid(e)) then e:SentenceStop() end end)
end)
