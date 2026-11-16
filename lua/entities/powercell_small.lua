if (StarGate ~= nil and StarGate.LifeSupportAndWire ~= nil) then
    StarGate.LifeSupportAndWire(ENT)
end

ENT.Type = "anim"
ENT.Base = "base_anim" --gmodentity
ENT.PrintName = "Small Powercell"
ENT.Author = "Soren MC, Spacebuild"
ENT.Category = "Ascension Gates"
ENT.WireDebugName = "Powercell_small"

list.Set("CAP.Entity", ENT.PrintName, ENT)

if CLIENT then
    if (SGLanguage!=nil and SGLanguage.GetMessage!=nil) then
        ENT.Category = SGLanguage.GetMessage("entity_main_cat");
    end
end

ENT.Spawnable = false
ENT.AdminSpawnable = false

-- AGP 2026-11-08: our own model, PowerGrid's smallest cell (AGP needs PowerGrid; batteries are PowerGrid's, not
-- SpaceGrid's). Half-Life 2's car battery only when PowerGrid's models are missing. The stool uses the same rule.
function ENT.AGPCellModel()
    local own = "models/agp_power/agp_cell_xs.mdl"
    return util.IsValidModel(own) and own or "models/items/car_battery01.mdl"
end


if SERVER then
	if (StarGate == nil or StarGate.CheckModule == nil or not StarGate.CheckModule("energy")) then return end
	AddCSLuaFile()

	function ENT:Initialize()
        -- AGP 2026-11-08: our own model (ENT.AGPCellModel above). The old model came only with Spacebuild: without it
        -- the cell removed itself at once ("You need to install Spacebuild!"; from the spawn menu a Lua error, Owner
        -- was not set yet)
        self.Entity:SetModel(self.AGPCellModel())
        self.Entity:PhysicsInit(SOLID_VPHYSICS)
        self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
        self.Entity:SetSolid(SOLID_VPHYSICS)
        local phys = self.Entity:GetPhysicsObject()

        if (phys:IsValid()) then
            phys:EnableMotion(false)
            phys:SetMass(10)
        end

        self:AddResource("energy", StarGate.CFG:Get("powercell_small", "energy_capacity", 100000))
        self:SupplyResource("energy", StarGate.CFG:Get("powercell_small", "energy_capacity", 8800000))
        self.MaxEnergy = StarGate.CFG:Get("powercell_small", "capacity", 8800000)
        self.Energy = StarGate.CFG:Get("powercell_small", "capacity", 8800000)
        self.Status = false
        self:CreateWireOutputs("Active", "Powercell %", "Powercell Energy")
        self.Connected = false
        self.CurrentEnergy = 0
        self.LastEnergy = 0
        self.MaxOutput = 20000
    end

    function ENT:SpawnFunction(p, t)
        if (not t.Hit) then return end
        local e = ents.Create("powercell_small")
        e:SetPos(t.HitPos + Vector(0, 0, 0))
        e:DrawShadow(true)
        e:SetVar("Owner", p)
        e:Spawn()
        e:Activate()
        local ang = p:GetAimVector():Angle()
        ang.p = 0
        ang.r = 0
        ang.y = (ang.y + 180) % 360
        e:SetAngles(ang)

        return e
    end


    function ENT:Think()
	    --if(self.depleted or not self.HasResourceDistribution) then self.Entity:NextThink(CurTime()+0.5); return true; end;
	    local energy = self:GetResource("energy")
        local nw_capacity = self:GetNetworkCapacity("energy")

        local rate = nw_capacity - energy

	    if (StarGate.WireRD.Connected(self)) then
	    	self.Status = true
	    end


	    local en = self:GetNetworkCapacity("energy") - self:GetResource("energy")

	    
	    self.Energy = math.Clamp(self.Energy - rate, 0, self.MaxEnergy) 
        if (self.Energy <= 0) then
        	self.Status = false
        else
        	self:SupplyResource("energy", en)
        end

	    ----OUTPUT---------
	    local percent = (self.Energy/self.MaxEnergy)*100 -- AGP 2026-11-08: local (was a global)
	    if (self.Status) then
	    	self.Entity:SetNWString("add", "ON")
		else
			self.Entity:SetNWString("add", "OFF")
	    end
	    self.Entity:SetNWString("energy%",percent)
	    self.Entity:SetNWString("energy",self.Energy)

	    -- AGP 2026-11-08: the Wire outputs were declared but never set (4 times a second is enough)
	    if (CurTime() >= (self.AGPWireNext or 0)) then
	    	self.AGPWireNext = CurTime() + 0.25
	    	self:SetWire("Active", self.Status and 1 or 0)
	    	self:SetWire("Powercell %", percent)
	    	self:SetWire("Powercell Energy", math.floor(self.Energy))
	    end

        self.Entity:NextThink(CurTime() + 0.01)
	    return true
	end
end


if CLIENT then

	ENT.Zpm_hud = surface.GetTextureID("VGUI/resources_hud/tier_3_small")

    function ENT:Initialize()
        self.Entity:SetNWString("add", "OFF")
        self.Entity:SetNWString("energy%", 0)
        self.Entity:GetNWString("energy",0)
    end	


    function ENT:Think()
        self.Entity:NextThink(CurTime() + 0.001)

        return true
    end

function ENT:Draw()

        self.Entity:DrawModel()

        if (not StarGate.VisualsMisc("cl_draw_huds", true)) then
            hook.Remove("HUDPaint", tostring(self.Entity) .. "powercell_small")

            return
        end

        hook.Remove("HUDPaint", tostring(self.Entity) .. "powercell_small")

        if (LocalPlayer():GetEyeTrace().Entity == self.Entity and EyePos():Distance(self.Entity:GetPos()) < 1024) then
            hook.Add("HUDPaint", tostring(self.Entity) .. "powercell_small", function()
                local w = 0
                local h = 260
                surface.SetTexture(self.Zpm_hud)
                surface.SetDrawColor(Color(255, 255, 255, 255))
                surface.DrawTexturedRect(ScrW() / 2 + 6 + w, ScrH() / 2 - 50 - h, 180, 360)
                surface.SetFont("center2")
                surface.SetFont("header")
                AGP.DrawBoxTitle(AGP.L("agp_ui_powercell_title", "Small Powercell"), ScrW() / 2 + 58 + w, ScrH() / 2 + 41 - h, Color(255, 255, 255, 255))

                if (SGLanguage ~= nil and SGLanguage.GetMessage ~= nil) then
                    draw.DrawText(AGP.L("agp_ui_energy", "Energy"), "center2", ScrW() / 2 + 46 + w, ScrH() / 2 + 65 - h, Color(209, 238, 238, 255), 0)         
                end

                if (IsValid(self.Entity)) then
                	add = self.Entity:GetNWString("add","OFF")
                    energyPercent = self.Entity:GetNWString("energy%",0)
                    energy = self.Entity:GetNWString("energy",0)
                end
                local color = Color(255, 255, 255, 255)
                surface.SetFont("center")
                if (add == "ON") then
                 	color = Color(0, 255, 0, 255)
            	else
            		color = Color(255, 0, 0, 255)
            	end

                if (SGLanguage ~= nil and SGLanguage.GetMessage ~= nil) then
                    draw.SimpleText(AGP.L("hud_sts_" .. string.lower(add), add), "center", ScrW() / 2 + 135 + w, ScrH() / 2 + 40 - h, color, 0)   -- the server sends the English state name; the status words exist in every language file
                end

                draw.SimpleText(tostring(math.Round(energyPercent,2)).."%", "center", ScrW() / 2 + 85 + w, ScrH() / 2 + 67 - h, Color(255, 255, 255, 255), 0)
                draw.SimpleText(tostring(energy), "center", ScrW() / 2 + 46 + w, ScrH() / 2 + 85 - h, Color(255, 255, 255, 255), 0)
            end)
        end
    end
	function ENT:OnRemove()
	    hook.Remove("HUDPaint", tostring(self.Entity) .. "powercell_small")
	end
end

