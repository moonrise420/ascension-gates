if (StarGate ~= nil and StarGate.LifeSupportAndWire ~= nil) then
    StarGate.LifeSupportAndWire(ENT)
end

ENT.Type = "anim"
ENT.Base = "base_anim" --gmodentity
ENT.PrintName = "Power Hub"
ENT.Author = "Soren"
ENT.WireDebugName = "Power Hub"
ENT.Category = "Moonwatcher:Machines"
ENT.Spawnable = false
ENT.AdminSpawnable = false


if SERVER then
	if (StarGate == nil or StarGate.CheckModule == nil or not StarGate.CheckModule("energy")) then return end
    AddCSLuaFile()
	function ENT:Initialize()

		self.Entity:SetModel("models/naquada-reactor.mdl")
        self.Entity:SetMaterial("models/reactor-skin-off") -- AGP 2026-11-10: without "materials/" (with it the client drew the purple error texture)
		self.Entity:SetName("power_hub")
		self.Entity:PhysicsInit(SOLID_VPHYSICS)
		self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
		self.Entity:SetSolid(SOLID_VPHYSICS)
		self.InternalPower = 2000
		self.MaxTransfer = 100000
        self.Provider = nil
        self.Tickrate = 0
	end

	function ENT:RequestPower (entity, power_requested)
        if (power_requested <= self.InternalPower) then
            if (power_requested > self.MaxTransfer) then
                self.InternalPower = self.InternalPower - self.MaxTransfer
                return self.MaxTransfer
            else
                 self.InternalPower = self.InternalPower - power_requested
                 return power_requested
            end
        else
            self.InternalPower = math.Clamp(self.InternalPower - power_requested, 0, 999999999) 
            return self.InternalPower
        end
    end

	function ENT:Think()

        if (self.Provider != nil) then
            if (CurTime() > self.Tickrate) then
                self.InternalPower = self.InternalPower + self.Provider:RequestPower(self,40)
                self.Tickrate = CurTime() + 1
            end
        end


        self.Entity:SetNWString("energy",self.InternalPower)
        self.Entity:SetNWBool("add",self.Active)
	end
end


if CLIENT then

	ENT.Zpm_hud = surface.GetTextureID("VGUI/resources_hud/tier_7")

    function ENT:Initialize()
        self.Entity:SetNWBool("add", false)
        self.Entity:GetNWString("energy",0)
        self.Entity:GetNWString("deuterium",0)
        self.Entity:GetNWString("water",0)
        self.Entity:GetNWString("oxygen",0)
    end	


    function ENT:Think()
        self.Entity:NextThink(CurTime() + 1)

        return true
    end

function ENT:Draw()

        self.Entity:DrawModel()

        if (not StarGate.VisualsMisc("cl_draw_huds", true)) then
            hook.Remove("HUDPaint", tostring(self.Entity) .. "power_hub")

            return
        end

        hook.Remove("HUDPaint", tostring(self.Entity) .. "power_hub")

        if (LocalPlayer():GetEyeTrace().Entity == self.Entity and EyePos():Distance(self.Entity:GetPos()) < 1024) then
            hook.Add("HUDPaint", tostring(self.Entity) .. "power_hub", function()
                local w = 0
                local h = 260
                surface.SetTexture(self.Zpm_hud)
                surface.SetDrawColor(Color(255, 255, 255, 255))
                surface.DrawTexturedRect(ScrW() / 2 + 6 + w, ScrH() / 2 - 50 - h, 180, 360)
                surface.SetFont("center2")
                surface.SetFont("header")
                AGP.DrawBoxTitle(AGP.L("agp_ui_power_hub_title", "Power Hub"), ScrW() / 2 + 65 + w, ScrH() / 2 + 41 - h, Color(255, 255, 255, 255))

                if (SGLanguage ~= nil and SGLanguage.GetMessage ~= nil) then
                    draw.DrawText(AGP.L("agp_ui_energy", "Energy"), "center2", ScrW() / 2 + 48 + w, ScrH() / 2 + 65 - h, Color(209, 238, 238, 255), 0)   
                    draw.DrawText(AGP.L("agp_ui_deuterium", "Deuterium"), "center2", ScrW() / 2 + 48 + w, ScrH() / 2 + 85 - h, Color(209, 238, 238, 255), 0)
                    draw.DrawText(AGP.L("agp_ui_water", "Water"), "center2", ScrW() / 2 + 48 + w, ScrH() / 2 + 105 - h, Color(209, 238, 238, 255), 0)
                    draw.DrawText(AGP.L("agp_ui_oxygen", "Oxygen"), "center2", ScrW() / 2 + 48 + w, ScrH() / 2 + 125 - h, Color(209, 238, 238, 255), 0)     
                end

                if (IsValid(self.Entity)) then
                	add = self.Entity:GetNWBool("add",false)
                    energy = self.Entity:GetNWString("energy",0)
                    deuterium = self.Entity:GetNWString("deuterium",0)
                    water = self.Entity:GetNWString("water",0)
                    oxygen = self.Entity:GetNWString("oxygen",0)
                end

                local color = Color(255, 255, 255, 255)
                surface.SetFont("center")
                if (add == true) then
                 	color = Color(0, 255, 0, 255)
            	else
            		color = Color(255, 0, 0, 255)
            	end

                if (SGLanguage ~= nil and SGLanguage.GetMessage ~= nil) then
                    draw.SimpleText(add and AGP.L("hud_sts_on", "On") or AGP.L("hud_sts_off", "Off"), "center", ScrW() / 2 + 135 + w, ScrH() / 2 + 40 - h, color, 0)   -- the server sends a boolean (it used to show "true" / "false"); On / Off is short enough for the narrow corner
                end

                draw.SimpleText(tostring(energy), "center", ScrW() / 2 + 95 + w, ScrH() / 2 + 67 - h, Color(255, 255, 255, 255), 0)
                draw.SimpleText(tostring(deuterium), "center", ScrW() / 2 + 115 + w, ScrH() / 2 + 87 - h, Color(255, 255, 255, 255), 0)
                draw.SimpleText(tostring(water), "center", ScrW() / 2 + 95 + w, ScrH() / 2 + 107 - h, Color(255, 255, 255, 255), 0)
                draw.SimpleText(tostring(oxygen), "center", ScrW() / 2 + 95 + w, ScrH() / 2 + 127 - h, Color(255, 255, 255, 255), 0)
            end)
        end
    end
	function ENT:OnRemove()
	    hook.Remove("HUDPaint", tostring(self.Entity) .. "power_hub")
	end
end