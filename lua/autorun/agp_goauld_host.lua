--[[
	Ascension Gates (the author's wish: "right click makes Goa'uld out of NPCs or players"): a Goa'uld larva can
	take a host. The larva's right click on a person in reach (weapons/goauld_larva.lua) calls
	AGP.GoauldTake(host, by). Like in the series the host keeps his looks - what shows is the eyes: they glow when the
	symbiote takes over, now and then afterwards, and when the host is hurt.
	 * a player: stronger and healing by himself (150 health, 1 a second), the Goa'uld's people take him for one of
	   theirs, the Tau'ri's shoot at him; it ends with his death
	 * an NPC: from then on a Goa'uld - it sides with the Goa'uld's people, against the Tau'ri and against the players
	   who are not hosts themselves (the one who gave it the symbiote it leaves alone)
]]
AddCSLuaFile()
AGP = AGP or {}

if (SERVER) then
	util.AddNetworkString("AGP.GoauldEyes")

	local HOST_HEALTH = 150

	function AGP.GoauldEyes(e, secs)
		if (not IsValid(e)) then return end
		net.Start("AGP.GoauldEyes"); net.WriteEntity(e); net.WriteFloat(secs or 1.6); net.Broadcast()
	end

	local function side(npc) return AGP_NPC_SIDE and AGP_NPC_SIDE[npc.AGPNPC] end

	-- how our NPCs see a player: a host is one of the Goa'uld's, any other player one of the Tau'ri's
	local function npcsSee(ply)
		local host = ply.AGPGoauldHost == true
		for _, n in ipairs(ents.FindByClass("npc_*")) do
			if (IsValid(n) and n.AGPNPC and n.AddEntityRelationship) then
				local s = side(n)
				if (n.AGPGoauldBy == ply) then n:AddEntityRelationship(ply, D_LI, 99)
				elseif (s == "goauld") then n:AddEntityRelationship(ply, host and D_LI or D_HT, 99)
				elseif (s == "tauri") then n:AddEntityRelationship(ply, host and D_HT or D_LI, 99) end
			end
		end
	end

	-- true when `host` can be taken (a living person that is not a Goa'uld already)
	function AGP.GoauldCanTake(host)
		if (not IsValid(host) or host.AGPGoauldHost) then return false end
		if (host:IsPlayer()) then return host:Alive() end
		if (host:IsNPC()) then return host:Health() > 0 and host:LookupBone("ValveBiped.Bip01_Head1") ~= nil and side(host) ~= "wraith" end
		return false
	end

	function AGP.GoauldTake(host, by)
		if (not AGP.GoauldCanTake(host)) then return false end
		host.AGPGoauldHost = true
		host:SetNWBool("AGPGoauldHost", true)
		AGP.GoauldEyes(host, 2.2)
		if (host:IsPlayer()) then
			host:SetMaxHealth(math.max(host:GetMaxHealth(), HOST_HEALTH))
			host:SetHealth(math.max(host:Health(), HOST_HEALTH))
			host:ViewPunch(Angle(-8, 0, 0))
			npcsSee(host)
			if (AGP.SayAs) then
				AGP.SayAs(host, "center", "agp_goauld_taken", "A Goa'uld symbiote has taken you as its host.")
				if (IsValid(by) and by:IsPlayer() and by ~= host) then AGP.SayAs(by, "hint", "agp_goauld_took", "The symbiote has taken %s as its host.", host:Nick()) end
			end
		else
			host.AGPGoauldBy = IsValid(by) and by or nil
			host.AGPNPC = host.AGPNPC and (side(host) == "goauld") and host.AGPNPC or "agp_npc_gou"   -- from now on the Goa'uld's side
			host:SetMaxHealth(math.max(host:GetMaxHealth(), HOST_HEALTH)); host:SetHealth(host:GetMaxHealth())
			if (not IsValid(host:GetActiveWeapon())) then host:Give("weapon_zat") end
			for _, o in ipairs(ents.FindByClass("npc_*")) do
				if (o ~= host and IsValid(o) and o.AGPNPC and o.AddEntityRelationship) then
					local d = (side(o) == "goauld") and D_LI or D_HT
					host:AddEntityRelationship(o, d, 99); o:AddEntityRelationship(host, d, 99)
				end
			end
			for _, p in ipairs(player.GetAll()) do
				host:AddEntityRelationship(p, (p == by or p.AGPGoauldHost) and D_LI or D_HT, 99)
			end
			if (host.ClearEnemyMemory) then host:ClearEnemyMemory() end
			if (host:GetClass() == "npc_citizen") then host:Fire("RemoveFromPlayerSquad") end   -- (he follows nobody any more)
			if (AGP.SayAs and IsValid(by) and by:IsPlayer()) then AGP.SayAs(by, "hint", "agp_goauld_took_npc", "The symbiote has taken a host. He is a Goa'uld now.") end
		end
		return true
	end

	local function free(ply)
		if (not ply.AGPGoauldHost) then return end
		ply.AGPGoauldHost = nil
		ply:SetNWBool("AGPGoauldHost", false)
		npcsSee(ply)
	end
	hook.Add("PlayerDeath", "AGP.GoauldHost", free)
	hook.Add("PlayerSilentDeath", "AGP.GoauldHost", free)
	hook.Add("PlayerSpawn", "AGP.GoauldHost", function(ply) if (ply.AGPGoauldHost) then free(ply) end end)

	-- new NPCs of ours meet the hosts; a host NPC meets new players
	hook.Add("PlayerSpawnedNPC", "AGP.GoauldHost", function(_, npc)
		timer.Simple(0.2, function()
			if (not IsValid(npc) or not npc.AGPNPC) then return end
			for _, p in ipairs(player.GetAll()) do if (p.AGPGoauldHost) then npcsSee(p) end end
			for _, o in ipairs(ents.FindByClass("npc_*")) do
				if (o ~= npc and IsValid(o) and o.AGPGoauldHost and o.AddEntityRelationship) then
					local d = (side(npc) == "goauld") and D_LI or D_HT
					o:AddEntityRelationship(npc, d, 99); npc:AddEntityRelationship(o, d, 99)
				end
			end
		end)
	end)
	hook.Add("PlayerInitialSpawn", "AGP.GoauldHost", function(ply)
		for _, o in ipairs(ents.FindByClass("npc_*")) do
			if (IsValid(o) and o.AGPGoauldHost and o.AddEntityRelationship) then o:AddEntityRelationship(ply, D_HT, 99) end
		end
	end)

	-- the symbiote heals its host; the eyes glow now and then and when the host is hurt
	timer.Create("AGP.GoauldHost", 1, 0, function()
		for _, p in ipairs(player.GetAll()) do
			if (p.AGPGoauldHost and p:Alive()) then
				if (p:Health() < p:GetMaxHealth()) then p:SetHealth(math.min(p:GetMaxHealth(), p:Health() + 1)) end
				if (CurTime() > (p.AGPEyesAt or 0)) then p.AGPEyesAt = CurTime() + math.Rand(25, 60); if (p.AGPEyesOnce) then AGP.GoauldEyes(p, 1.4) end; p.AGPEyesOnce = true end
			end
		end
		for _, n in ipairs(ents.FindByClass("npc_*")) do
			if (IsValid(n) and n.AGPGoauldHost and n:Health() > 0 and CurTime() > (n.AGPEyesAt or 0)) then
				n.AGPEyesAt = CurTime() + math.Rand(20, 45)
				if (n.AGPEyesOnce) then AGP.GoauldEyes(n, 1.4) end
				n.AGPEyesOnce = true
			end
		end
	end)
	hook.Add("EntityTakeDamage", "AGP.GoauldHost", function(e, d)
		if (e.AGPGoauldHost and d:GetDamage() >= 5 and CurTime() > (e.AGPEyesHurt or 0)) then
			e.AGPEyesHurt = CurTime() + 4
			AGP.GoauldEyes(e, 1.0)
		end
	end)
	return
end

-- ------------------------------------------------------------------------------------------------------------ client
local glow = Material("sprites/light_glow02_add")
local active = {}

net.Receive("AGP.GoauldEyes", function()
	local e, secs = net.ReadEntity(), net.ReadFloat()
	if (IsValid(e)) then active[e] = { t0 = CurTime(), len = math.Clamp(secs, 0.3, 5) } end
end)

-- brightness over its time: up fast, held, away slowly
local function level(a)
	local k = (CurTime() - a.t0) / a.len
	if (k < 0 or k > 1) then return 0 end
	if (k < 0.12) then return k / 0.12 end
	if (k < 0.6) then return 1 end
	return 1 - (k - 0.6) / 0.4
end

hook.Add("PostDrawTranslucentRenderables", "AGP.GoauldEyes", function(depth, sky)
	if (sky or depth or not next(active)) then return end
	local me = LocalPlayer()
	for e, a in pairs(active) do
		local l = IsValid(e) and level(a) or 0
		if (not IsValid(e) or CurTime() > a.t0 + a.len) then
			active[e] = nil
		elseif (l > 0 and not (e == me and not me:ShouldDrawLocalPlayer()) and not e:GetNoDraw() and not e:IsDormant()) then
			local id = e:LookupAttachment("eyes")
			local att = id and id > 0 and e:GetAttachment(id)
			if (att) then
				local f, r = att.Ang:Forward(), att.Ang:Right()
				render.SetMaterial(glow)
				for _, s in ipairs({ -1.3, 1.3 }) do
					local p = att.Pos + r * s + f * 0.6
					render.DrawSprite(p, 5.5 * l + 1, 5.5 * l + 1, Color(255, 236, 170, 255 * l))
					render.DrawSprite(p, 2.2, 2.2, Color(255, 255, 255, 255 * l))
				end
			end
		end
	end
end)

-- the host himself: his sight flares gold for a moment
hook.Add("RenderScreenspaceEffects", "AGP.GoauldEyes", function()
	local a = active[LocalPlayer()]
	if (not a) then return end
	local l = level(a)
	if (l <= 0) then return end
	surface.SetDrawColor(255, 225, 140, 70 * l)
	surface.DrawRect(0, 0, ScrW(), ScrH())
end)
