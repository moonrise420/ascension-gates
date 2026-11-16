-- Ascension Gates: Destiny Power Node - one of Destiny's conduit junctions as a Grid Power node (see agp_power_base.lua).
-- Works like the medium Power Node: links everything that touches it or stands on its deck, shows the network on its
-- screen; with Spacebuild running it is a real Resource Distribution node (the base creates the RD network).
-- Model: our own (Code/notes/models/agp_destiny_asgard_models.py), the old models/circuitdest.mdl never existed.
ENT.Type = "anim"
ENT.Base = "agp_power_base"
ENT.AGPNameKey = "agp_ent_destiny_node"
ENT.PrintName = AGP.L("agp_ent_destiny_node", "Destiny Power Node")
ENT.Author = "moonrise420"
ENT.Category = "Ascension Gates"   -- spawn tab: "tech" group (stargate/client/menu.lua, by class name)
if (SGLanguage ~= nil and SGLanguage.GetMessage ~= nil) then
    ENT.Category = SGLanguage.GetMessage("entity_main_cat")
end
ENT.WireDebugName = "Destiny Power Node"
ENT.AGPKind = "node"
ENT.AGPModel = "models/agp_power/agp_node_destiny.mdl"
ENT.AGPCapacity = 0
ENT.AGPRate = 0
ENT.AGPSurface = { pos = Vector(-16.91, 0, 13.05), w = 40.8, h = 15.2, tilt = 20 }
list.Set("CAP.Entity", ENT.PrintName, ENT)

if SERVER then
    AddCSLuaFile()

    local function limitReached(p)
        local cv = GetConVar("CAP_destiny_node_max")
        if (not cv or not IsValid(p) or not p:IsPlayer()) then return false end
        if (p:GetCount("CAP_destiny_node") + 1 > cv:GetInt()) then
            p:SendLua("GAMEMODE:AddNotify(SGLanguage.GetMessage(\"entity_limit_dest_node\"), NOTIFY_ERROR, 5); surface.PlaySound( \"buttons/button2.wav\" )")
            return true
        end
        return false
    end

    function ENT:SpawnFunction(p, t, cls)
        if (limitReached(p)) then return end
        local base = scripted_ents.GetStored("agp_power_base")
        local e = base and base.t.SpawnFunction(self, p, t, cls or "destiny_node")
        if (IsValid(e) and IsValid(p) and p:IsPlayer()) then
            p:AddCount("CAP_destiny_node", e)
            e.Owner = p
        end
        return e
    end

    function ENT:PreEntityCopy()   -- AGP 2026-11-10: its Wire links are kept in dupes
    	if (StarGate.WireRD) then StarGate.WireRD.PreEntityCopy(self) end
    end

    function ENT:PostEntityPaste(p, Ent, CreatedEntities)
        if (StarGate and StarGate.NotSpawnable and StarGate.NotSpawnable(Ent:GetClass(), p)) then
            self:Remove()
            return
        end
        if (limitReached(p)) then
            self:Remove()
            return
        end
        if (IsValid(p) and p:IsPlayer()) then
            p:AddCount("CAP_destiny_node", self)
            self.Owner = p
        end
        if (StarGate and StarGate.WireRD and StarGate.WireRD.PostEntityPaste) then
            StarGate.WireRD.PostEntityPaste(self, p, Ent, CreatedEntities)
        end
    end

    if (StarGate and StarGate.CAP_GmodDuplicator) then
        duplicator.RegisterEntityClass("destiny_node", StarGate.CAP_GmodDuplicator, "Data")
    end
end
