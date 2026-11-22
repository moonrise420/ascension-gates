--[[
	A global library with  bunch of usefull
	functions often used in entities on serverside
	Copyright (C) 2011 Madman07
]]
--
function StarGate.FindPlayer(pos, range)
    local ply = false
    local dist = range

    for _, v in pairs(player.GetAll()) do
        local p_dist = (pos - v:GetPos()):Length()

        if (dist >= p_dist) then
            dist = p_dist
            ply = true
        end
    end

    return ply
end

function StarGate.FindIris(gate)
    local iris

    if (IsValid(gate) and gate.IsStargate) then
        for _, v in pairs(ents.FindInSphere(gate:GetPos(), 10)) do
            if v.IsIris then
                iris = v
            end
        end
    end

    return iris
end

function StarGate.FindGate(ent, dist, super)
    local gate
    local pos = ent:GetPos()

    for _, v in pairs(ents.FindByClass("stargate_*")) do
        if (not v.IsStargate or v.IsSupergate and not super) then continue end
        local sg_dist = (pos - v:GetPos()):Length()

        if (dist >= sg_dist) then
            dist = sg_dist
            gate = v
        end
    end

    return gate
end

function StarGate.FindKino(p)
    local number = 0
    local KinoEnt = {}

    for _, v in pairs(ents.FindByClass("kino_ball*")) do
        if (v.Owner == p) then
            table.insert(KinoEnt, v)
            number = number + 1
        end
    end

    return number, KinoEnt
end

function StarGate.FindShield(ent)
    local gate
    local dist = 10000
    local pos = ent:GetPos()

    for _, v in pairs(ents.FindByClass("shield_core_button")) do
        local sg_dist = (pos - v:GetPos()):Length()

        if (dist >= sg_dist) then
            dist = sg_dist
            gate = v
        end
    end

    return gate
end

function StarGate.IsInsideShieldCore(ent, core)
    if (core.ShShap == 1) then
        return StarGate.IsInEllipsoid(ent:GetPos(), core, core.Size)
    elseif (core.ShShap == 2) then
        return not StarGate.IsInCuboid(ent:GetPos(), core, core.Size) -- why NOT?? onclient it work correct, strange.
    elseif (core.ShShap == 3) then
        return StarGate.IsInAltantisoid(ent:GetPos(), core, core.Size)
    end
end

-- added by AlexALX for nuke explosions
-- anywat it bit buggy with shield core somewhy, wrong angles or so
function StarGate.IsInShield(ent)
    local pos = ent:GetPos()
    local shields = {"shield", "ship_shield", "shield_core_buble"}

    for b, s in pairs(shields) do
        for c, v in pairs(ents.FindByClass(s)) do
            local sh_dist = (pos - v:GetPos()):Length()

            if (s == "shield") then
                if (sh_dist <= v.Size and not v:IsContainment()) then return true end
            elseif (s == "ship_shield") then
                local Size = 200
                if (sh_dist <= Size) then return true end
            else
                if (not v.Depleted and v.Enabled and StarGate.IsInsideShieldCore(ent, v)) then return true end
            end
        end
    end

    return false
end

-- Ugly, no validation, but works :p
function StarGate.GetMultipleOwner(ent)
    local own = ent

    if IsValid(own) then
        if own:IsPlayer() then return own end
        if (own.Owner and own.Owner:IsPlayer()) then return own.Owner end
        own = ent:GetOwner()

        if IsValid(own) then
            if own:IsPlayer() then return own end
            if (own.Owner and own.Owner:IsPlayer()) then return own.Owner end
            own = ent:GetOwner()

            if IsValid(own) then
                if own:IsPlayer() then return own end
                if (own.Owner and own.Owner:IsPlayer()) then return own.Owner end
            end
        end
    end
end

-- From stargate group system by AlexALX
messageblock = messageblock or {}

function StarGate.ReloadSystem(groupsystem)
    if (messageblock[tostring(groupsystem)]) then return end
    local system = "Galaxy System"

    if (groupsystem) then
        system = "Group System"
    end

    for k, v in pairs(player.GetHumans()) do
        v:SendLua("LocalPlayer():ChatPrint(SGLanguage.GetMessage(\"stargate_reload\",\"" .. system .. "\"))")
    end

    RunConsoleCommand("stargate_reload")

    if (tostring(groupsystem) == "true") then
        messageblock["false"] = false
    elseif (tostring(groupsystem) == "false") then
        messageblock["true"] = false
    end

    messageblock[tostring(groupsystem)] = true
    timer.Remove("_StarGate.ReloadSystemMessage")

    timer.Create("_StarGate.ReloadSystemMessage", 5.25, 1, function()
        messageblock[tostring(groupsystem)] = false
        StarGate.ReloadedSystemMessage()
    end)
end

function StarGate.ReloadedSystemMessage()
    for k, v in pairs(player.GetHumans()) do
        v:SendLua("LocalPlayer():ChatPrint(SGLanguage.GetMessage(\"stargate_reloaded\"))")
    end
end

--####################
-- stargateextras.lua
--####################
StarGate.STARGATE_DEFAULT_ENERGY_CAPACITY = StarGate.CFG:Get("gate_overloader", "energyCapacity", 580000)
StarGate.COOLING_PER_CYCLE = StarGate.CFG:Get("gate_overloader", "coolingPerCycle", 300)

function StarGate.Think()
end

function StarGate.DrawGateHeatEffects(gate)
    StarGate.TintGate(gate)

    if (gate.excessPower and gate.excessPowerLimit) then
        -- The amount of excess power required to destabalise the stargate
        local destabalisingExcessPower = 3 * (gate.excessPowerLimit / 4)

        if (gate.excessPower >= destabalisingExcessPower) then
            -- Chance of the gates flickering if excessPower is at least 3/4 of the limit
            if (math.random(0, gate.excessPower) >= destabalisingExcessPower) then
                if (gate.malfunction) then
                    gate.malfunction:Fire("DoSpark", "", 0)
                end

                StarGate.MakeGateFlicker(gate)
            end
        end
    end
end

function StarGate.MakeGateFlicker(gate)
    local remoteGate = StarGate.GetRemoteStargate(gate)
    if (remoteGate == nil or remoteGate:IsValid() == false) then return false end

    if (gate.Flicker) then
        gate:Flicker()
        remoteGate:Flicker()
    elseif (gate.EventHorizon) then
        gate.EventHorizon:SetColor(Color(150, 150, 150, 255))
        remoteGate.EventHorizon:SetColor(Color(150, 150, 150, 255))

        local function resetColour(entity)
            if (entity and entity:IsValid()) then
                entity:SetColor(Color(255, 255, 255, 255))
            end
        end

        timer.Simple(0.5, function()
            resetColour(gate.EventHorizon)
        end)

        timer.Simple(0.5, function()
            resetColour(remoteGate.EventHorizon)
        end)
    end
end

function StarGate.StopUpdateGateTemperatures(gate)
    if timer.Exists("UpdateGateTemp" .. gate:EntIndex()) then
        timer.Destroy("UpdateGateTemp" .. gate:EntIndex())
    end
end

function StarGate.UpdateGateTemperatures(gate)
    timer.Create("UpdateGateTemp" .. gate:EntIndex(), StarGate.CYCLE_INTERVAL, 0, function()
        local shouldCoolGate = true

        for _, overloader in pairs(ents.FindByClass("gate_overloader")) do
            if (overloader.remoteGate == gate) then
                shouldCoolGate = false
            end
        end

        if (shouldCoolGate) then
            StarGate.CoolGate(gate)
        end

        StarGate.DrawGateHeatEffects(gate)
        StarGate.CauseHeatDamage(gate)
    end)
end

function StarGate.CoolGate(gate)
    if (gate == nil) then
        Msg("Gate passed to CoolGate(gate) cannot be nil.\n")

        return flase
    elseif (gate.excessPower == nil or gate.excessPower <= 0) then
        return false
    end

    -- The amount of energy lost as the gate cools
    local energyDissipated = math.min(StarGate.COOLING_PER_CYCLE, gate.excessPower)
    -- Dissipate some of the excess power
    gate.excessPower = gate.excessPower - energyDissipated
    -- What is this? it seems like CONSUME energy with LS3, so i just disable this.
    --if(StarGate.HasResourceDistribution) then
    -- Reduce the amount of energy the gate can store by the amount dissipated
    -- This will result in the gate returning to its original energy capacity once it has completely cooled

    return true
end

function StarGate.TintGate(gate)
    if (gate == nil or not IsValid(gate)) then
        Msg("Gate passed to StarGate.TintGate was not valid.\n")

        return
    elseif (gate.excessPower == nil or gate.excessPowerLimit == nil) then
        return
    end

    if (gate.excessPower < 0) then
        gate.excessPower = 0
    end

    local col = gate.OrigColor or Color(255, 255, 255)
    local tintAmount = 255 * (gate.excessPower / gate.excessPowerLimit)
    -- fix for universe stargate by AlexALX
    -- new fix much better now in meta/universe code
    gate:SetColor(Color(math.Clamp(col.r + tintAmount, 0, 255), math.Clamp(col.g - tintAmount, 0, 255), math.Clamp(col.b - tintAmount, 0, 255), col.a))
    -- also custom color support
    local iris = StarGate.GetIris(gate)

    if (StarGate.IsEntityValid(iris)) then
        tintAmount = math.min(tintAmount * 2, 128)
        local col = iris.OrigColor or Color(255, 255, 255)
        iris:SetColor(Color(math.Clamp(col.r + tintAmount, 0, 255), math.Clamp(col.g - tintAmount, 0, 255), math.Clamp(col.b - tintAmount, 0, 255), col.a))
        iris.OrigColor = col
    end

    gate.OrigColor = col
end

function StarGate.EmitHeat(pos, damage, radius, inflictor)
    if (CombatDamageSystem) then
        cds_heatpos(pos, damage, radius)

        return true
    elseif (gcombat) then
        gcombat.emitheat(pos, radius, damage, inflictor)

        return true
    else
        return false
    end
end

function StarGate.HeatEntity(entity, damage, radius, inflictor)
    if (StarGate.EmitHeat(entity:GetPos(), damage, radius, inflictor)) then
        return true
    else
        if (entity.burnInflictor == nil) then
            local burnInflictor = ents.Create("point_hurt")
            burnInflictor:SetOwner(inflictor)
            burnInflictor:SetPos(StarGate.GetEntityCentre(entity))
            burnInflictor:SetKeyValue("DamageDelay", 0.2)
            burnInflictor:SetKeyValue("DamageType", 8) -- Burn damage
            burnInflictor:Spawn()
            burnInflictor:Activate()
            burnInflictor:SetParent(entity)
            entity.burnInflictor = burnInflictor
        end

        entity.burnInflictor:SetKeyValue("DamageRadius", radius)
        entity.burnInflictor:SetKeyValue("Damage", damage)
    end
end

function StarGate.CoolEntity(entity)
    if (entity.burnInflictor) then
        entity.burnInflictor:Remove()
        entity.burnInflictor = nil
    end
end

function StarGate.CauseHeatDamage(gate)
    if (gate == nil) then
        Msg("Gate passed to CauseHeatDamage(gate) cannot be nil.\n")

        return false
    elseif (gate.excessPower == nil) then
        return false
    end

    if (gate.excessPower > gate.excessPowerLimit / 2 and IsValid(gate.overloader)) then
        -- Make gate cause damage to nearby players due to extreme heat
        local heatDamage = math.Round(2 * (gate.excessPower / gate.excessPowerLimit))
        local heatRadius = 500 * (gate.excessPower / gate.excessPowerLimit)
        local overloaderOwner = gate.overloader:GetVar("Owner", gate.overloader:GetOwner())
        StarGate.HeatEntity(gate, heatDamage, heatRadius, overloaderOwner)

        if (gate.excessPower > 3 * (gate.excessPowerLimit / 4) and StarGate.GetEntityCentre(gate)) then
            for k, entity in pairs(ents.FindInSphere(StarGate.GetEntityCentre(gate), heatRadius)) do
                if (entity ~= gate) then
                    entity:Ignite(2, 25)
                end
            end
        end

        return true
    else
        StarGate.CoolEntity(gate)

        return false
    end
end

-- Jams the given gate, preventing it from closing the current connection
-- Also overrides USE key behaviour on the gate so that this key instead toggles the iris
-- Returns: whether the gate could be jammed
function StarGate.JamRemoteGate(gate,attero)
    if attero == nil then attero = false end

    if attero then
        if (gate == nil or gate:IsValid() == false) then
            Msg("The stargate passed to JamRemoteGate(gate) is not valid.\n")

            return false
        elseif (StarGate.IsStargateOpen(gate) == false or StarGate.IsStargateOutbound(gate) ==false) then
            Msg("The stargate passed to JamRemoteGate(gate) does not have an outbound wormhole open.\n")

            return false
        elseif (gate.jammed == true) then
            return true
        end
    else
        if (gate == nil or gate:IsValid() == false) then
            Msg("The stargate passed to JamRemoteGate(gate) is not valid.\n")

            return false
        elseif (StarGate.IsStargateOpen(gate) == false or StarGate.IsStargateOutbound(gate)) then
            Msg("The stargate passed to JamRemoteGate(gate) does not have an outbound wormhole open.\n")

            return false
        elseif (gate.jammed == true) then
            return true
        end
    end


    function DummyFunction(...)
        return false
    end

    -- Override remote gate's functions to prevent shutdown
    gate.backups = {}
    gate.backups.AcceptInput = gate.AcceptInput
    gate.AcceptInput = DummyFunction
    -- Do not simply disable pressing the 'use' key on a gate - instead make this toggle the iris (the one function of the remote gate that should not be disabled)
    gate.backups.EmergencyShutdown = gate.EmergencyShutdown
    gate.EmergencyShutdown = DummyFunction
    gate.backups.DeactivateStargate = gate.DeactivateStargate
    gate.DeactivateStargate = DummyFunction
    gate.backups.Close = gate.Close
    gate.Close = DummyFunction
    gate.backups.ActivateStargate = gate.ActivateStargate
    gate.ActivateStargate = DummyFunction
    gate.backups.Open = gate.Open
    gate.Open = DummyFunction
    gate.backups.auto_close = gate.auto_close
    gate.auto_close = false
    gate.jammed = true
    
    if (StarGate.GetRemoteStargate(gate) == nil or StarGate.GetRemoteStargate(gate):IsValid() == false) then
        Msg("The remote gate was invalid.\n")
        return false
    end

    local localGate = StarGate.GetRemoteStargate(gate)
    localGate.backups = {}
    -- Override local gate's functions to un-jam the remote gate when the connection is closed locally
    localGate.backups.AcceptInput = localGate.AcceptInput

    -- AGP: called as methods (gate:AcceptInput(...)), so the gate comes first; the arguments were shifted by one
    localGate.AcceptInput = function(ent, name, activator, caller, data)
        if (name == "Use" or name == nil) then return end
        StarGate.UnJamGate(localGate)
        return localGate:AcceptInput(name, activator, caller, data)
    end
    
    -- For compatibility with UnJamGate
    localGate.backups.EmergencyShutdown = localGate.EmergencyShutdown
    localGate.EmergencyShutdown = DummyFunction
    localGate.backups.DeactivateStargate = localGate.DeactivateStargate
    localGate.DeactivateStargate = DummyFunction
    localGate.backups.ActivateStargate = localGate.ActivateStargate

    localGate.ActivateStargate = function(ent, inbound, fast)
        StarGate.UnJamGate(StarGate.GetRemoteStargate(localGate))
        return localGate:ActivateStargate(inbound, fast)
    end

    localGate.backups.Open = localGate.Open
    localGate.Open = DummyFunction
    localGate.backups.Close = localGate.Close
    localGate.Close = DummyFunction
    localGate.backups.auto_close = localGate.auto_close
    localGate.auto_close = false
    localGate.jammed = true

    return true
end

function StarGate.UnJamGate(gate)
    if (gate == nil) then
        Msg("The stargate passed to UnJamGate(gate) cannot be nil.\n")

        return false
    elseif (gate:IsValid() == false) then
        return false
    elseif (gate.jammed ~= true or gate.backups == nil) then
        return true
    end

    gate.AcceptInput = gate.backups.AcceptInput
    gate.EmergencyShutdown = gate.backups.EmergencyShutdown
    gate.DeactivateStargate = gate.backups.DeactivateStargate
    gate.Close = gate.backups.Close
    gate.ActivateStargate = gate.backups.ActivateStargate
    gate.Open = gate.backups.Open
    gate.auto_close = gate.backups.auto_close
    gate.jammed = false

    return StarGate.UnJamGate(StarGate.GetRemoteStargate(gate))
end

function StarGate.JamDHD(dhd, duration)
    if (dhd == nil) then
        Msg("The DHD passed to JamDHD(dhd) cannot be nil.\n")

        return false
    elseif (dhd:IsValid() == false) then
        return false
    end

    if (dhd.SetBusy) then
        dhd:SetBusy(duration)
    else
        dhd.busy = true
    end

    return true
end

function StarGate.GetGateMarker(gate)
    if (gate == nil) then
        Msg("Gate passed to GetGateMarker(gate) cannot be nil.\n")

        return
    end

    if (gate.centreMarker == nil) then
        gate.centreMarker = ents.Create("info_target")
        gate.centreMarker:SetPos(StarGate.GetEntityCentre(gate))
        gate.centreMarker:SetName("GateMarker" .. gate:EntIndex())
        gate.centreMarker:Spawn()
        gate.centreMarker:SetParent(gate)
    end

    return gate.centreMarker
end

function StarGate.GetStargateEnergyCapacity(gate)
    if (StarGate.HasResourceDistribution and (gate.resources or gate.resources2)) then
        return StarGate.WireRD.GetUnitCapacity(gate, "energy")
    else
        return gate.capacity
    end
end

function StarGate.SetStargateEnergyCapacity(gate, capacity)
    if (StarGate.HasResourceDistribution) then
        StarGate.WireRD.AddResource(gate, "energy", capacity)
    end

    gate.capacity = capacity
end

-- Credit to aVoN for this function originally
-- Has since been cleaned up and modified to work with both old and new gates
function StarGate.DestroyStargate(gate)
    if (not StarGate.IsStargateDialling(gate) and (gate.last_vaporize == nil or gate.last_vaporize + 10 < CurTime())) then
        gate.last_vaporize = CurTime()

        if (gate.use_nuke == nil or gate.use_nuke == true) then
            local nuke = ents.Create("gate_nuke")

            if (nuke and nuke:IsValid()) then
                nuke:Setup(StarGate.GetEntityCentre(gate), 100)
                nuke:Spawn()
                nuke:Activate()
            end
        else
            local gatePos = StarGate.GetEntityCentre(gate)
            local fx = EffectData()
            fx:SetOrigin(gatePos)
            -- AGP: "Unstable_Explosion" never existed (no visual): a fireball and the unstable gate's debris burst
            util.Effect("Explosion", fx)
            util.Effect("unstable_zap_explosion", fx)
            util.BlastDamage(gate.Entity, gate, gatePos, 2048, 1000)
        end

        StarGate.UnJamGate(gate)

        if (IsValid(StarGate.GetRemoteStargate(gate))) then
            StarGate.GetRemoteStargate(gate):DeactivateStargate(true)
        end
        gate:DeactivateStargate(true)
        if (StarGate.IsProtectedByGateSpawner(gate) == false) then
            for _, dhd in pairs(gate:FindDHD(true)) do
                if (StarGate.IsProtectedByGateSpawner(dhd) == false) then
                    dhd:Remove()
                end
            end

            timer.Simple(1, function()
                if (IsValid(gate)) then
                    gate:Remove()
                end
            end, nil)
        else
            gate.excessPower = 0
            gate.isOverloading = false -- Reset this so that the gate can be overloaded again in the future
        end
    end
end

function StarGate.GetIris(gate)
    if (gate.iris) then
        return gate.iris
    elseif (StarGate.IsEntityValid(gate.Iris)) then
        return gate.Iris
    end

    for _, entity in pairs(ents.FindInSphere(gate:GetPos(), 10)) do
        if (entity.IsIris) then return entity end
    end

    return nil
end

function StarGate.IsIrisClosed(gate)
    return gate.irisclosed == true or (gate.IsBlocked and gate:IsBlocked(true) == true)
end

-- ramdom_names.lua
-- This code makes it so gates get random names when they spawn! :D
-- Created by cartman300, edited by AlexALX
local function RandomAddress(max, exclude)
    local chr = "ABCDEFGHIJKLMNOPQRSTUVWXYZ@1234567890"
    local ret = ""

    while (ret:len() < max) do
        local ll = math.random(1, chr:len())
        local r = chr:sub(ll, ll)
        local match = "[^" .. ret .. exclude .. "%z]"
        if not r:match(match) then continue end
        ret = ret .. r
    end

    return ret
end

local function RandomNumber(max)
    local exclude = ""
    local chr = "0123456789"
    local ret = ""

    while (ret:len() < max) do
        local ll = math.random(1, chr:len())
        local r = chr:sub(ll, ll)
        local match = "[^" .. ret .. exclude .. "%z]"
        if not r:match(match) then continue end
        ret = ret .. r
    end

    return ret
end

local function RandomString(max)
    local exclude = ""
    local chr = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local ret = ""

    while (ret:len() < max) do
        local ll = math.random(1, chr:len())
        local r = chr:sub(ll, ll)
        local match = "[^" .. ret .. exclude .. "%z]"
        if not r:match(match) then continue end
        ret = ret .. r
    end

    return ret
end

local function RandomAll(max)
    local chr = "1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local ret = ""
    local exclude = ""

    while (ret:len() < max) do
        local ll = math.random(1, chr:len())
        local r = chr:sub(ll, ll)
        local match = "[^" .. ret .. exclude .. "%z]"
        if not r:match(match) then continue end
        ret = ret .. r
    end

    return ret
end

function StarGate.RandomGateName(ply, ent, count, wire, mode)
    local conv = GetConVar("stargate_random_address")

    if (conv and conv:GetBool() or wire) then
        if (IsValid(ent) and ent.IsStargate and ent:GetClass() ~= "stargate_orlin") then
            if (mode == nil or mode <= 1) then
                local randadr = ""

                if (GetConVar("stargate_group_system"):GetBool()) then
                    randadr = RandomAddress(6, ent:GetGateGroup())
                else
                    randadr = RandomAddress(6, "@0")
                end

                local valid = false

                for k, v in pairs(ents.FindByClass("stargate_*")) do
                    if (v.IsStargate) then
                        if (v:GetGateGroup() == ent:GetGateGroup() and randadr == v:GetGateAddress()) then
                            valid = true
                            break
                        end
                    end
                end

                count = count or 1

                if valid then
                    if (count > 5) then return end -- fix infinity loop
                    StarGate.RandomGateName(ply, ent, count + 1, wire, mode)

                    return
                end

                ent:SetGateAddress(randadr)
            end

            if (mode == nil or mode <= 0 or mode >= 2) then
                if (ent:GetClass() == "stargate_atlantis") then
                    ent:SetGateName("M" .. RandomNumber(1) .. RandomString(1) .. "-" .. RandomNumber(1) .. RandomAll(2))
                elseif (ent:GetClass() == "stargate_supergate") then
                    ent:SetGateName(RandomAll(7))
                elseif (ent.IsUniverseGate) then
                    ent:SetGateName("U-" .. RandomNumber(5))
                else
                    ent:SetGateName("P" .. RandomNumber(1) .. RandomString(1) .. "-" .. RandomNumber(1) .. RandomAll(2))
                end
            end
        end
    end
end

hook.Add("PlayerSpawnedSENT", "RandomGateName", StarGate.RandomGateName)