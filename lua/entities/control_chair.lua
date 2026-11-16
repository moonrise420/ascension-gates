if (StarGate ~= nil and StarGate.LifeSupportAndWire ~= nil) then
    StarGate.LifeSupportAndWire(ENT)
end

include("stargate/shared/mw_library.lua")

ENT.Base = "base_anim"
ENT.Type = "anim"
ENT.PrintName = "Control Chair"
ENT.Author = "RononDex, Markjaw, Soren"
ENT.Category = "Ascension Gates: Ships"
list.Set("CAP.Entity", ENT.PrintName, ENT)
ENT.AutomaticFrameAdvance = true

if CLIENT then
	if (SGLanguage!=nil and SGLanguage.GetMessage!=nil) then
		ENT.Category = SGLanguage.GetMessage("entity_ships_cat");
		ENT.PrintName = SGLanguage.GetMessage("entity_control_chair");
	end


    ENT.Controlchair_bottomleft = surface.GetTextureID("VGUI/resources_hud/control_chair_bottomleft")
    ENT.Controlchair_bottomright = surface.GetTextureID("VGUI/resources_hud/control_chair_bottomright")
    
    ENT.ViewPos = Vector(0, 0, 100)
    ENT.ViewFace = ((Vector(0, 0, 100) + Vector(0, 0, 20)) - Vector(0, 0, 100)):Angle()
    ENT.PlayerMouse = false


    function ENT:Initialize()
        self.DAmt = 0
        self.Dist = -200
        self.UDist = 90
        self.NextUse = CurTime()
    end

    function ENT:HandleMessageFromServer(originEntity, subject, ...)
        local data1 = select(1, ...)
        local data2 = select(2, ...)
        local data3 = select(3, ...)

        if subject == "controlchair_targetmenu_v2" then
            TargetControlMenu(originEntity, data1)
        elseif subject == "controlchair_interact" then
            ControlChair_Interact(originEntity, data1)
        elseif subject == "controlchair_click" then
            ControlChair_Click(originEntity)
        end
    end

    function ENT:OnRemove()
        hook.Remove("HUDPaint", tostring(self.Entity) .. "CChair")


    end

    function ENT:Draw()
        local p = LocalPlayer()
        local Controlling = p:GetNWBool("Control")
        local chair_initialized = p:GetNetworkedBool("chair_initialized")
        local sc_vehicle = p:GetNWEntity("ScriptedVehicle",nil)

        self:DrawModel()

        if (Controlling and IsValid(self.Entity) and (sc_vehicle==self.Entity)) then

            hook.Add("HUDPaint", tostring(self.Entity) .. "CChair", function()
            -------- Bottom Left--------------------------------------------------------------------------------
                local w = -930
                local h = -310

                surface.SetTexture(self.Controlchair_bottomleft)
                surface.SetDrawColor(Color(255, 255, 255, 255))
                surface.DrawTexturedRect(ScrW() / 2 - 42 + w, ScrH() / 2 - 50 - h, 360, 360)
                draw.DrawText(AGP.L("agp_ui_ancient_control_chair", "Ancient Control Chair"), "HudHintTextLarge", ScrW() / 2 + 48 + w, ScrH() / 2 + 41 - h, color_white, 0)

                draw.DrawText(AGP.L("agp_ui_r_engage_rotation", "R: Engage rotation"), "HudHintTextLarge", ScrW() / 2 - 5 + w, ScrH() / 2 + 70 - h, color_white, 0)
                
                if (self:GetNetworkedBool("Rotate",true) == true) then
                    draw.DrawText(AGP.L("agp_ui_online", "Online"), "HudHintTextLarge", ScrW() / 2 + 130 + w, ScrH() / 2 + 70 - h, Color(0, 255, 0, 255), 0)
                else
                    draw.DrawText(AGP.L("agp_ui_offline", "Offline"), "HudHintTextLarge", ScrW() / 2 + 130 + w, ScrH() / 2 + 70 - h, Color(255, 0, 0, 255), 0)
                end

                draw.DrawText(AGP.L("agp_ui_d_enable_shield", "D: Enable shield"), "HudHintTextLarge", ScrW() / 2 - 5 + w, ScrH() / 2 + 90 - h, color_white, 0)

                if (self:GetNetworkedBool("Shield_online",false) == true) then
                    draw.DrawText(AGP.L("agp_ui_online", "Online"), "HudHintTextLarge", ScrW() / 2 + 130 + w, ScrH() / 2 + 90 - h, Color(0, 255, 0, 255), 0)
                else
                    draw.DrawText(AGP.L("agp_ui_offline", "Offline"), "HudHintTextLarge", ScrW() / 2 + 130 + w, ScrH() / 2 + 90 - h, Color(255, 0, 0, 255), 0)
                end

                draw.DrawText(AGP.L("agp_ui_left_mouse_button_fire_drones", "Left mouse button: fire drones"), "HudHintTextLarge", ScrW() / 2 - 5 + w, ScrH() / 2 + 110 - h, color_white, 0)
                draw.DrawText(AGP.L("agp_ui_space_hold_stardrive", "Space (hold): Stardrive"), "HudHintTextLarge", ScrW() / 2 - 5 + w, ScrH() / 2 + 130 - h, color_white, 0)


            -------- Bottom Right--------------------------------------------------------------------------------
                w = 655
                h = -310
                surface.SetTexture(self.Controlchair_bottomright)
                surface.SetDrawColor(color_white)
                surface.DrawTexturedRect(ScrW() / 2 - 42 + w, ScrH() / 2 - 50 - h, 360, 360)
                draw.DrawText(AGP.L("agp_ui_power", "Power"), "HudHintTextLarge", ScrW() / 2 + w, ScrH() / 2 + 41 - h, color_white, 0)
                if self:GetNetworkedString("ZPM_Online","Inactive") == "Active" then
                    draw.DrawText(AGP.L("agp_ui_internal_zpm", "Internal ZPM:") .. " ", "HudHintTextLarge", ScrW() / 2 + w, ScrH() / 2 + 61 - h, color_white, 0)
                    draw.DrawText(AGP.L("agp_ui_online", "Online"), "HudHintTextLarge", ScrW() / 2 +100 + w, ScrH() / 2 + 61 - h, color_white, 0)

                    draw.DrawText(AGP.L("agp_ui_zpm_90", "ZPM %:") .. " ", "HudHintTextLarge", ScrW() / 2 + w, ScrH() / 2 + 81 - h, color_white, 0)
                    draw.DrawText( math.Round(self:GetNetworkedInt("ZPM_Percentage",0),1).."%", "HudHintTextLarge", ScrW() / 2 +60 + w, ScrH() / 2 + 81 - h, color_white, 0)
                    
                else
                    draw.DrawText(AGP.L("agp_ui_internal_zpm", "Internal ZPM:") .. " ", "HudHintTextLarge", ScrW() / 2 + w, ScrH() / 2 + 61 - h, color_white, 0)
                    draw.DrawText(AGP.L("agp_ui_offline", "Offline"), "HudHintTextLarge", ScrW() / 2 +100 + w, ScrH() / 2 + 61 - h, color_white, 0)
                end
            end)
        elseif ((not (Controlling))) then
            hook.Remove("HUDPaint", tostring(self.Entity) .. "CChair")
        end

        if (chair_initialized and (sc_vehicle==self.Entity)) then
            self:DynLight(true)

        elseif (not (chair_initialized)) then
            self:DynLight(false)
        end
    end

    local function Data(um)
        local p = LocalPlayer()
        p.Controlling = um:ReadBool()
        p.Enabled = um:ReadBool()
        p.DroneCount = um:ReadShort()
        p.Chair = um:ReadEntity()
    end

    usermessage.Hook("ControlChair", Data)

     
	local chair_zoom = 0
	hook.Add("InputMouseApply", "Chair_Zoom", function(cmd, x, y, ang)
        local p = LocalPlayer()
        if (p.Controlling) then
	       chair_zoom = chair_zoom + cmd:GetMouseWheel() * -2
        end
	end)

    function ControlChair_Interact(senderEntity, isMouseActive)
    local localPlayer = LocalPlayer()
        if localPlayer.Controlling then
            localPlayer:SetNWBool("player_chair_mouse", isMouseActive)
        end
    end

    function ControlChair_Click(originEntity)
        local pilot = LocalPlayer()
        if (pilot.Controlling) then
            if (gui.MousePos()!=0) then
                t = util.TraceLine( util.GetPlayerTrace( pilot, gui.ScreenToVector(gui.MousePos()) ) )
                SendMessageToServer("nil",originEntity, "Chair_ClientClickToChair", t.Entity, t.HitPos)
            end
        end
    end

    function ControlCHCalcView(Player, Origin, Angles, FieldOfView)
        local view = {}
        local p = Player
        local self = p:GetNetworkedEntity("ScriptedVehicle", NULL)
        local chair = p:GetNWEntity("chair")
        if (not IsValid(chair) or not IsValid(self) or self:GetClass() ~= "control_chair") then return end
        -- AGP: hand-flown drone: first person view from the lead drone (the server sets/clears AGP_ChairLead;
        -- as soon as it is gone, removed or the player left the chair the normal chair view below comes back)
        local lead = p:GetNW2Entity("AGP_ChairLead")
        if (IsValid(lead) and p:Alive() and not lead:GetNoDraw()) then
            local ang = p:EyeAngles()
            local vel = lead:GetVelocity()
            local fwd = vel:LengthSqr() > 100 and vel:GetNormalized() or ang:Forward()
            return { origin = lead:GetPos() + fwd * 45, angles = ang, fov = FieldOfView, drawviewer = false }
        end
        if IsValid(self) then
            if (not p:GetNWBool("player_chair_mouse",false)) then
                local pos = chair:GetPos() + Vector(0, 0, 100) - p:GetAimVector()*(math.Clamp(chair_zoom, 4, 400) *30)
                local face = ((chair:GetPos() + Vector(0, 0, 20)) - pos):Angle()

                self.ViewPos = pos
                self.ViewFace = face   
            end

            if (p:GetNWBool("player_chair_mouse",false)) then 
                p:SetNWVector("chairvec", self.ViewPos)
                p:SetNWVector("chairang", self.ViewFace)
            end

            view.origin = self.ViewPos
            view.angles = self.ViewFace
            view.fov = nil
            return view
        end
    end

    hook.Add("CalcView", "ControlCHCalcView", ControlCHCalcView)

    -- AGP: small key help while seated (wrapped to its box, AGP colours); in the drone camera a reticle and a short hint
    surface.CreateFont("AGPChairHint", { font = "Roboto", size = 16, weight = 500, extended = true })
    surface.CreateFont("AGPChairHintB", { font = "Roboto", size = 17, weight = 800, extended = true })
    local function wrapText(text, font, maxw)
        surface.SetFont(font)
        local out, line = {}, ""
        for word in string.gmatch(text, "%S+") do
            local try = (line == "") and word or (line .. " " .. word)
            if (line ~= "" and surface.GetTextSize(try) > maxw) then
                out[#out + 1] = line
                line = word
            else
                line = try
            end
        end
        if (line ~= "") then out[#out + 1] = line end
        return out
    end
    hook.Add("HUDPaint", "AGP.ControlChairHint", function()
        local p = LocalPlayer()
        if (not IsValid(p) or not p:GetNWBool("ControlChair_InChair", false)) then return end
        local chair = p:GetNWEntity("ScriptedVehicle", NULL)
        if (not IsValid(chair) or chair:GetClass() ~= "control_chair") then return end
        local function L(k, d, ...) return AGP and AGP.L and AGP.L(k, d, ...) or string.format(d, ...) end
        local C = AGP and AGP.Colors or {}
        local cBg, cEdge, cText, cDim, cAcc, cAcc2 = C.bg or Color(14, 20, 30, 235), C.edge or Color(44, 70, 110), C.text or Color(225, 235, 245), C.textDim or Color(150, 165, 185), C.accent or Color(56, 150, 240), C.accent2 or Color(255, 160, 50)
        local lead = p:GetNW2Entity("AGP_ChairLead")
        local flying = IsValid(lead) and not lead:GetNoDraw()
        local lines = {}   -- { text, colour }
        if (flying) then
            local cx, cy = ScrW() / 2, ScrH() / 2
            surface.SetDrawColor(cAcc2)
            surface.DrawOutlinedRect(cx - 14, cy - 14, 28, 28)
            surface.DrawRect(cx - 1, cy - 1, 3, 3)
            lines[#lines + 1] = { L("agp_chair_hint_fly", "Drone camera: steer with the mouse. The other drones follow and hit what it hits."), cText }
        elseif (not p.Enabled) then
            lines[#lines + 1] = { L("agp_chair_hint_arm", "S: lean back to arm the chair. E: stand up."), cText }
            lines[#lines + 1] = { L("agp_chair_hint_targets", "Right mouse or 1: target list"), cDim }
        else
            lines[#lines + 1] = { L("agp_chair_hint_fire", "Left mouse: fire drones (click = 1, hold = up to 6)"), cText }
            lines[#lines + 1] = { L("agp_chair_hint_targets", "Right mouse or 1: target list"), cText }
            local locked = chair:GetNW2Entity("AGP_ChairLockEnt")
            if (IsValid(locked)) then
                local name = locked:IsPlayer() and locked:Nick() or ((locked.PrintName and locked.PrintName ~= "") and locked.PrintName or locked:GetClass())
                lines[#lines + 1] = { L("agp_chair_hint_locked", "Locked on: %s. The drones home in by themselves.", name), cAcc2 }
            elseif (chair:GetNW2Bool("AGP_ChairWired", false)) then
                lines[#lines + 1] = { L("agp_chair_hint_wired", "Wired target: the drones fly to the wired position."), cAcc2 }
            else
                lines[#lines + 1] = { L("agp_chair_hint_manual", "No target locked: you fly the first drone yourself, the others follow it."), cAcc }
            end
            lines[#lines + 1] = { L("agp_chair_hint_other", "R: rotation   D: shield   Space: stardrive   W: sit up   E: stand up"), cDim }
        end
        if ((p.DroneCount or 0) > 0) then
            lines[#lines + 1] = { L("agp_chair_hint_drones", "Drones in flight: %d", p.DroneCount or 0), cDim }
        end
        local w = math.Clamp(ScrW() * 0.24, 240, 380)
        local pad, lh = 10, 19
        local rows = {}
        for _, l in ipairs(lines) do
            for _, s in ipairs(wrapText(l[1], "AGPChairHint", w - pad * 2)) do rows[#rows + 1] = { s, l[2] } end
        end
        local h = pad * 2 + 22 + #rows * lh
        local x, y = ScrW() - w - 16, math.floor(ScrH() * 0.22)
        draw.RoundedBox(8, x - 2, y - 2, w + 4, h + 4, cEdge)
        draw.RoundedBox(7, x, y, w, h, cBg)
        draw.SimpleText(L("agp_chair_hint_title", "Control chair"), "AGPChairHintB", x + pad, y + pad, cAcc)
        for i, r in ipairs(rows) do
            draw.SimpleText(r[1], "AGPChairHint", x + pad, y + pad + 22 + (i - 1) * lh, r[2])
        end
    end)

    function ENT:DynLight()
        local p = LocalPlayer()
        local pos = self:GetPos() + self:GetUp() * 100
        local Chair_init = p:GetNWInt("chair_initialized")

        if (IsValid(self)) then
            if (Chair_init > 0) then
                if (StarGate.VisualsMisc("cl_chair_dynlights")) then
                    local dynlight = DynamicLight(self:EntIndex() + 4096)
                    dynlight.Pos = pos
                    if (Chair_init == 2) then
                        dynlight.Brightness = 10
                    else
                        dynlight.Brightness = 7
                    end
                    dynlight.Size = 184
                    dynlight.Decay = 1024
                    dynlight.R = 25
                    dynlight.G = 255
                    dynlight.B = 255
                    dynlight.DieTime = CurTime() + 2
                end
            end
        end
    end
end

if CLIENT then
    -- Hide weapon selection HUD and block switching while in chair
    hook.Add("HUDShouldDraw", "ControlChair_HideWeaponSelect", function(name)
        local ply = LocalPlayer()
        if IsValid(ply) and ply:GetNWBool("ControlChair_InChair", false) then
            -- Hide weapon selection HUD elements
            if name == "CHudWeaponSelection" then
                return false
            end
        end
    end)
    
    -- Block weapon selection completely on client
    hook.Add("PlayerBindPress", "ControlChair_BlockWeaponSwitch_Client", function(ply, bind, pressed)
        if IsValid(ply) and ply:GetNWBool("ControlChair_InChair", false) then
            -- Block weapon switching binds
            if string.find(bind, "slot") or bind == "invnext" or bind == "invprev" then
                return true
            end
        end
    end)
end


if SERVER then
    if (StarGate == nil or StarGate.CheckModule == nil or not StarGate.CheckModule("ship")) then return end
    AddCSLuaFile()

    util.AddNetworkString("controlchair_interact")
    util.AddNetworkString("controlchair_click")
    util.AddNetworkString("Chair_ClientClickToChair")

    util.PrecacheSound("thrusters/hover01.wav")
	util.PrecacheSound("ambient/explosions/exp2.wav")
	util.PrecacheSound("tech/hover01_end2.wav")

    hook.Add("PlayerSwitchWeapon", "ControlChair_PreventWeaponSwitch", function(ply, oldWeapon, newWeapon)
        if IsValid(ply) and ply:GetNWBool("ControlChair_InChair", false) then
            return true -- Prevent weapon switch
        end
    end)

    -- Lock weapon functionality while controlling chair
    hook.Add("Think", "ControlChair_LockWeapons", function()
        for _, ply in ipairs(player.GetAll()) do
            if IsValid(ply) and ply:GetNWBool("ControlChair_InChair", false) then
                local weapon = ply:GetActiveWeapon()
                if IsValid(weapon) then
                    -- Disable weapon attacks by setting next fire times to far future
                    weapon:SetNextPrimaryFire(CurTime() + 1)
                    weapon:SetNextSecondaryFire(CurTime() + 1)
                end
            end
        end
    end)


    ENT.Models = {
        Base = Model("models/soren/chair_zpm/chair_base_zpm.mdl"),
        Chair = Model("models/soren/drone_chair_v2/drone_chair_v2.mdl"),
        Base2 = Model("models/soren/soclseige_2/soclseige_2.mdl"),
        Base3 = Model("models/markjaw/drone_chair/chair_base_2.mdl")
    }

    ENT.Sounds = {
        Activate = Sound("tech/chair2.wav"),
        Activate2 = Sound("jumper/puddlestartup2.wav"),
        Activate3 = Sound("control_chair/chair_hologram.wav"),
        Deactivate = Sound("control_chair/chair_exit.wav"),
        Deactivate2 = Sound("tech/chair2_exit.wav")
    }

    function ENT:SpawnFunction(pl, tr)
        local e = ents.Create("control_chair")
        e:SetPos(tr.HitPos + Vector(0, 0, 10))
        local ang = pl:GetAimVector():Angle()
        ang.p = 0
        ang.r = 0
        ang.y = ang.y % 360
        e:SetAngles(ang)
        e:Spawn()
        e:Activate()

        e:AddChair(pl)
        e:AddZPMHub(pl)
        self.Owner = pl

        return e
    end

    function ENT:Initialize()
        self:SetModel(self.Models.Base)
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetUseType(SIMPLE_USE)
        self.ActiveTime = 0
        self:CreateWireInputs("X", "Y", "Z", "Start X", "Start Y", "Start Z", "Entity [ENTITY]", "Vector [VECTOR]")
        self:CreateWireOutputs("X", "Y", "Z", "Vector [VECTOR]", "LitUp", "Active", "Secondary")
        --############ Drone vars
        self.Target = Vector(0, 0, 0)
        self.DroneMaxSpeed = (8000)
        self.AllowAutoTrack = true
        self.AllowEyeTrack = false
        self.TrackTime = 1000000
        self.TargetClass = nil
        self.WireEnt = nil -- AGP: entity from the "Entity" wire input (drone target while valid)
        self.WireEntActive = false -- AGP: true while the wired entity drives self.Target
        self.WireTarget = nil -- AGP: last target from the Vector / X / Y / Z inputs (restored when the wired entity goes away)
        self.Drones = {}
        self.DroneCount = 0
        self.pilotPos = Vector(0,0,0)
        --########################
        self.PlayerTouching = nil
        self.RotateIsOn = true
        self.Enabled = false
        self.Debug = false
        self.EyeTrack = false
        self.Pressed = false
        self.Shield = nil
        self.AllowedPlayers = {};
        self.Strength = 100
        self.StrengthShield = 100
        self.ShieldColor = Vector(0, 255, 0)
        self.ShieldActive = false
        self.Ragdoll_Angle = 0
        self.Targets = {}
        self.Teststring = nil
        self.RotationSpeed = 0
        self.PilotViewing = false
        self.RequireATAGene = StarGate.CFG:Get("cap_enhanced_cfg","ATA_gene_active",false);
        self.LastCheckTime = 0
        self.RegisteredLaunchers = {}
        --###### Energy Vars
        self:AddResource("energy", 1)

        if (self.HasRD) then
            self.ShouldConsume = true
        else
            self.ShouldConsume = false
        end

        self.CanActivate = true
        self.Antarticatype = false
        self.Atlantistype = false
        self.Socleseige_type = false

        if (self.Antarticatype) then
    		self:SetSkin(3)
        else
        	self:SetSkin(0)
        end

        self.NextUse = CurTime()
        self.FirePos = Vector(0, 0, 0)
        self.StartPos = self:GetPos() + self:GetForward() * -150
        self.LastSwitch = CurTime()
        local phys = self:GetPhysicsObject()

        if (phys:IsValid()) then
            phys:SetMass(20000)
            phys:Wake()
        end
    end

    function ENT:UpdateTarget(targetclass)
        self.TargetClass = targetclass
    end

    
    function ENT:Targetlist()
        if(IsValid(self.Targets)) then
    	    self.Target = self.Targets[1]:GetPos()
        end
    end


    function ENT:SwitchType()
    	if (self.Antarticatype) then
    		self:SetSkin(0)
    		self.Chair:SetSkin(0)

    		self.Antarticatype=false
    	else
    		self:SetSkin(3)
    		self.Chair:SetSkin(2)
    		self.Antarticatype=true
    	end
    end

    function ENT:AtlantisVersion()
    	if (self.Socleseige_type) then
            self:SetModel(self.Models.Base)
    		self:PhysicsInit(SOLID_VPHYSICS)
        	self:SetMoveType(MOVETYPE_VPHYSICS)
        	self:SetSolid(SOLID_VPHYSICS)
        	self:SetUseType(SIMPLE_USE)
    		local phys = self:GetPhysicsObject()
        	if (phys:IsValid()) then
            	phys:SetMass(20000)
            	phys:Wake()
        	end
    		self.Chair:SetParent(nil)
    		self.Chair:SetPos(self:GetPos() + self:GetUp() * 15)
    		self.Chair:SetAngles(self:GetAngles())
    		self.Chair:SetParent(self)
            self:AddZPMHub()
    		self.Socleseige_type=false    
    	elseif (self.Atlantistype) then
            if (IsValid(self.ZpmHub)) then self.ZpmHub:Remove() end
    		self:SetModel(self.Models.Base2)
    		self:PhysicsInit(SOLID_VPHYSICS)
        	self:SetMoveType(MOVETYPE_VPHYSICS)
        	self:SetSolid(SOLID_VPHYSICS)
        	self:SetUseType(SIMPLE_USE)
    		local phys = self:GetPhysicsObject()
        	if (phys:IsValid()) then
            	phys:SetMass(20000)
            	phys:Wake()
        	end
    		self.Chair:SetParent(nil)
    		self.Chair:SetPos(self:GetPos() + self:GetUp() * 9)
    		self.Chair:SetAngles(self:GetAngles())
    		self.Chair:SetParent(self)
            self.Atlantistype=false
    		self.Socleseige_type=true
        else
            if (IsValid(self.ZpmHub)) then self.ZpmHub:Remove() end
            self:SetModel(self.Models.Base3)
            self:PhysicsInit(SOLID_VPHYSICS)
            self:SetMoveType(MOVETYPE_VPHYSICS)
            self:SetSolid(SOLID_VPHYSICS)
            self:SetUseType(SIMPLE_USE)
            local phys = self:GetPhysicsObject()
            if (phys:IsValid()) then
                phys:SetMass(20000)
                phys:Wake()
            end
            self.Chair:SetParent(nil)
            self.Chair:SetPos(self:GetPos() + self:GetUp() * 15)
            self.Chair:SetAngles(self:GetAngles())
            self.Chair:SetParent(self)
            self.Atlantistype=true
    		
    	end
    end

    function ENT:Hit(strength, normal, pos)
    end

    function ENT:RegisterLauncher(launcher)
        if IsValid(launcher) then
            self.RegisteredLaunchers[launcher] = true
        end
    end

    function ENT:UnregisterLauncher(launcher)
        if IsValid(launcher) then
            self.RegisteredLaunchers[launcher] = nil
        end
    end

    function ENT:SearchForTargets(pos, targetlist)

    	local allTargets = ents.FindInSphere( self:GetPos(), 4000 )

    	for k,v in pairs(allTargets) do
    		
    		if (allTargets[k]:GetClass() == self.TargetClass) then
    			table.insert(targetlist,v)
    		end
    	end
    end

    function ENT:SpawnShield()
        local e = ents.Create("shield")
        e.Size = 200
        e.DrawBubble = true
        e:SetPos(self.Entity:GetPos())
        e:SetAngles(self.Entity:GetAngles())
        e:SetColor(Color(230, 230, 230, 255))
        e:SetParent(self.Entity)
        e:Spawn()
        e:SetNWBool("containment", false)
        e:DrawBubbleEffect()
        e:SetTrigger(true)
        self.Entity:EmitSound("shields/shield_engage.mp3", 90, math.random(90, 110))
        --this sound is part of a workshop addon so we should change it later
        self.ShieldActive = true

        if(e and e:IsValid() and not e.Disable) then -- When our new shield mentioned, that there is already a shield
			self.Shield = e;
			self:SetNoCollideWithAllowedPlayers();
		end
        return e
    end

    function ENT:SetNoCollideWithAllowedPlayers()
		if(self.AllowedPlayers ~= {}) then
			for _,ply in pairs(self.AllowedPlayers) do
				if IsValid(ply) and ply:IsPlayer() then
					if not self.Shield:IsContainment() then
						self.Shield.nocollide[ply] = true;
					else
						self.Shield.nocollide[ply] = false;
					end
				end
			end
		end
	end


    function ENT:HandleMessageFromClient(ply, originEntity, receiverEntityID, subject, ...)
        if originEntity:GetClass() ~= self:GetClass() then return end   -- only messages from our own chair

        local data1 = select(1, ...)
        local data2 = select(2, ...)
        local data3 = select(3, ...)


        if subject == "ControlChair_Relay_from_client_target" then
            self:UpdateTarget(data1)
        elseif subject == "ToggleChairMode_Atlantis" then 

            local entity = data1
            if (util.IsValidModel("models/soclesiege.mdl")) then       
                ply:EmitSound( "buttons/button24.wav" )
                AGP.SayAs(ply, "info", "agp_chair_version", "Chair version switched")
                entity:AtlantisVersion()
            elseif (entity.Atlantistype) then
                ply:EmitSound( "buttons/button8.wav" )
                AGP.SayAs(ply, "error", "agp_chair_skip", "Skipping this chair version")
                AGP.SayAs(ply, "error", "agp_missing_model", "Error: the client or server is missing a model: (%s)", "soclesiege")
                entity:AtlantisVersion()
                entity:AtlantisVersion()
            else
                ply:EmitSound( "buttons/button24.wav" )
                AGP.SayAs(ply, "info", "agp_chair_version", "Chair version switched")
                entity:AtlantisVersion()
            end

        elseif subject == "ToggleChairMode" then 
                local entity = data1
                ply:EmitSound( "buttons/button24.wav" )
                AGP.SayAs(ply, "info", "agp_chair_type", "Chair type switched")
                entity:SwitchType()
        elseif subject == "Chair_ClientClickToChair" then
                self:ChairClickwire(data1,data2,ply)
        end


        --     --print(originEntity)
        --     --print(receiverEntityID)

    end

    function ENT:RemoveShield()
        if (self.Shield:IsValid()) then
            self.Shield:DrawBubbleEffect(true)

            timer.Simple(1, function ()
                if (IsValid(self.Shield)) then
                    self.Shield.Strength = -1
                    self.Shield:Remove()
                    self.Shield = nil
                    self.ShieldActive = false
                end
            end)
            self:EmitSound("shields/shield_disengage.mp3", 90, math.random(90, 110))
            

        end
    end

    function ENT:OnRemove()
        self:AGPEndManual() -- AGP: drone camera back / off
        if (self.Pilot) then
            self.Pilot:SetNWBool("Control",false)
            self.Pilot:SetNWBool("Controlling",false)
        end
        if (self.Controlling) then
            self:DeactivateChair(self.Pilot)
        end
        self:StopSound("tech/asgard_holo_loop.wav")
        if (self.Shield and self.Shield:IsValid()) then
            self.Shield:Remove()
        end
        if (IsValid(self.ZpmHub)) then
            self.ZpmHub:Remove()
        end

        StarGate.WireRD.OnRemove(self)
        -- AGP: removed self:Remove() here (OnRemove runs because the chair is already being removed)
    end

    function ENT:AddChair(p)
        local e = ents.Create("prop_physics")
        e:SetModel(self.Models.Chair)
        if (self:GetModel()=="models/soclesiege.mdl") then
        	e:SetPos(self:GetPos() + self:GetUp() * 9)
        else
        	e:SetPos(self:GetPos() + self:GetUp() * 15)
    	end
        e:SetAngles(self:GetAngles())
        e:Spawn()
        e:Activate()
        e:SetParent(self)

        if (self.Antarticatype) then
    		e:SetSkin(3)
    	else
        	e:SetSkin(0)
        end
        self.Chair = e
        e.AGPControlChair = self   -- AGP: E on the seat itself (a separate prop) works like E on the chair
        self:SetNetworkedEntity("Chair", self.Chair)
        p:SetNWInt("chair_initialized", 0)

        if CPPI and IsValid(p) and e.CPPISetOwner then
            e:CPPISetOwner(p)
        end
    end

    function ENT:AddZPMHub(p)
        local e = ents.Create("chair_zpm_hub")
        if (IsValid(e)) then e.DoNotDuplicate = true end   -- (2026-11-12: built by its parent, which builds it again after a save or a paste - copied as well it was there twice)
        e:SetModel("models/soren/zpm_slot/zpm_slot.mdl")
        e:SetPos(self:GetPos() + self:GetUp()*2 + self:GetRight()*-39.80 + self:GetForward()*-69.32)
        e:SetAngles(self:GetAngles())
        e:Spawn()
        e:Activate()
        e.Chair = self
        self.ZpmHub = e
        e:HubLink(self)
        if CPPI and IsValid(p) and e.CPPISetOwner then
            e:CPPISetOwner(p)
        end
        constraint.Weld(e,self.Entity,0,0,0,true);
    end

    function ENT:LowPriorityThink()
    	self.Strength = 100
    	if (self.Pressed == true) then
            timer.Simple(2, function()

                self.Pressed = false
            end)
        end
    end

    hook.Add("PlayerUse", "AGP.ControlChairSeat", function(ply, ent)
        local chair = ent.AGPControlChair
        if (not IsValid(chair)) then return end
        if ((ply.AGPChairUseT or 0) < CurTime()) then ply.AGPChairUseT = CurTime() + 0.6; chair:Use(ply) end
        return false
    end)

    function ENT:Use(p)
        if (IsValid(self) and (not (self.Controlling))) then
            if (self.RequireATAGene) then
                if(StarGate.HasATA(p,true)) then
                    self:ActivateChair(p)
                end
            else
                self:ActivateChair(p)
            end
        end
    end

    function ENT:ActivateChair(p)
        if (self.ShouldConsume) then
            if (self:GetResource("energy")) > 500 then
                self.CanActivate = true
            else
                self.CanActivate = false
            end
        end

        if (not self.CanActivate and IsValid(p) and (self.NoPowerMsg or 0) < CurTime()) then   -- AGP: say why nothing happens
            self.NoPowerMsg = CurTime() + 2
            p:ChatPrint(AGP and AGP.L and AGP.L("agp_chair_nopower", "[Control chair] No power: put a charged ZPM into the chair's ZPM hub (it needs 500 energy to start).") or "[Control chair] No power: put a charged ZPM into the chair's ZPM hub (it needs 500 energy to start).")
        end
        if (self.CanActivate) then
            if (self.NextUse < CurTime()) then
                p:Spectate(OBS_MODE_CHASE)
                p:DrawWorldModel(false)
                p:DrawViewModel(false)
            
                self.Pilot = p
                self:SpawnRagdoll()
                p:SetNetworkedEntity("ScriptedVehicle", self)
                p:SetViewEntity(self)
                p:SetEyeAngles(self.Chair:GetAngles())
                p:SetNWBool("ControlChair_InChair", true)
                p:SetNWEntity("chair", self.Chair)
                self:ConsumeResource("energy", 500)
                self.Controlling = true
                
                self.ActiveTime = 0
                self.NextUse = CurTime() + 1
                self.Nextthink = true
            end
        end
    end

    function ENT:DeactivateChair(p)
        self:AGPEndManual() -- AGP: leaving the chair always ends the drone camera
        self.AGPFireHeld, self.AGPAltHeld = false, false
        if (self.Pilot) then
            self.Pilot:SetNWBool("Control",false)
            self.Pilot:SetNWBool("ControlChair_InChair", false)

            if (self:GetResource("energy") < 500) then
                self.Pilot:SetNWInt("chair_initialized", 0)
            else
                self.Pilot:SetNWInt("chair_initialized", 1)
            end
        end

        self.Pilot:UnSpectate()
        self.Pilot:DrawWorldModel(true)
        self.Pilot:DrawViewModel(true)

        self.Pilot:SetNetworkedEntity("ScriptedVehicle", NULL)
        self.Pilot:SetViewEntity(NULL)
        if (AGP and AGP.ShipRespawnPilot) then AGP.ShipRespawnPilot(self.Pilot) else self.Pilot:Spawn() end -- AGP 2026-11-08: keeps armour and ammo, no Ha'tak bunk move (agp_ship_shield.lua)
        self.Pilot:SetParent()
        self.Pilot:SetPos(self:GetPos() + self:GetRight() * 60 + self:GetUp() * 20)

        if (IsValid(self.Chair)) then
            if (self.Antarticatype) then
    			self.Chair:SetSkin(2)
    		else
        		self.Chair:SetSkin(0)
        	end
        end

        self.PilotViewing = false
        self.Pilot:SetNWBool("Chair_viewing",false)
        SendMessageToClient(self.Pilot, self, "controlchair_interact",false)

        self.Pilot:SetParent()
        self.Pilot:SetNWEntity("chair", NULL)
        self:SupplyResource("energy", 500)
        self.Ragdoll:Remove()
        self.Controlling = false
        self.NextUse = CurTime() + 3
        self.Nextthink = false
        self.Enabled = false
        firstsound = false
    end
    function ENT:ChairClickwire(ChairclickT,clickposition,player)

        local inputs = WireLib.GetPorts(ChairclickT)
        local alt = player:KeyDown(IN_SPEED)

        local Controlchair = player:GetNWEntity("chair",NULL):GetParent()


        local playernumber = player:GetNWInt("ChairWireNumber",0)

        if ChairclickT:GetClass() == "cap_doors_frame" then
             for i=1,#inputs do
             end
            ChairclickT:TriggerInput(inputs[1][1],1)
        elseif (istable(inputs)) then
            
            if (playernumber == 0) then


                 for i=1,# inputs do

                 end
            else
                if alt then ChairclickT:TriggerInput(inputs[playernumber][1],0) else ChairclickT:TriggerInput(inputs[playernumber][1],1) end
            end
        else
            -- AGP: target priority: wired entity > wired Vector / X / Y / Z > pilot aim (the click only aims when nothing is wired)
            if (IsValid(Controlchair) and not (Controlchair.HasWiredTarget and Controlchair:HasWiredTarget())) then
                Controlchair.Target = clickposition
            end
        end
    end

    -- AGP: true when the "Entity" input holds a valid entity, or a Vector / X / Y / Z input is wired to something
    function ENT:HasWiredTarget()
        if (IsValid(self.WireEnt)) then return true end
        if (self.Inputs) then
            for _, name in ipairs({"Vector", "X", "Y", "Z"}) do
                local inp = self.Inputs[name]
                if (inp and IsValid(inp.Src)) then return true end
            end
        end
        return false
    end

    -- AGP: the "Entity" input makes the wired entity the drone target (its centre, a new vector every Think).
    -- When it becomes invalid or is unwired, the target falls back to the last Vector / X / Y / Z value.
    function ENT:UpdateWireEntTarget()
        -- AGP: for the seated pilot's HUD (NW2 only sends when the value changes)
        self:SetNW2Entity("AGP_ChairLockEnt", IsValid(self.WireEnt) and self.WireEnt or NULL)
        self:SetNW2Bool("AGP_ChairWired", (not IsValid(self.WireEnt)) and self:HasWiredTarget())
        if (IsValid(self.WireEnt)) then
            self.Target = self.WireEnt:LocalToWorld(self.WireEnt:OBBCenter())
            self.WireEntActive = true
        elseif (self.WireEntActive) then
            self.WireEntActive = false
            if (self.WireTarget) then
                self.Target = Vector(self.WireTarget.x, self.WireTarget.y, self.WireTarget.z)
            end
        end
    end

    function ENT:RelayToHud(inputtable,ply)

        
    end

    hook.Add( "PlayerButtonDown", "ChairWirePlayerButtonDown", function( ply, button )
        
        if (ply:GetNWBool("Chair_viewing",true)) then
            
            if button == 2 then 
                ply:SetNWInt("ChairWireNumber",1)
            elseif button == 3 then 
                ply:SetNWInt("ChairWireNumber",2)
            elseif button == 4 then 
                ply:SetNWInt("ChairWireNumber",3)
            elseif button == 5 then 
                ply:SetNWInt("ChairWireNumber",4)
            elseif button == 6 then 
                ply:SetNWInt("ChairWireNumber",5)
            elseif button == 7 then 
                ply:SetNWInt("ChairWireNumber",6)
            elseif button == 8 then 
                ply:SetNWInt("ChairWireNumber",7)
            elseif button == 9 then 
                ply:SetNWInt("ChairWireNumber",8)
            elseif button == 10 then 
                ply:SetNWInt("ChairWireNumber",9)
            elseif button == 11 then 
                ply:SetNWInt("ChairWireNumber",10)
            end

            if CLIENT and not IsFirstTimePredicted() then
                return
            end
        else return end
    end)


    hook.Add( "PlayerButtonUp", "ChairWirePlayerButtonUp", function( ply, button )
        
        if (ply:GetNWBool("Chair_viewing",true)) then
            if button == 2 then 
                ply:SetNWInt("ChairWireNumber",0)
            elseif button == 3 then 
                ply:SetNWInt("ChairWireNumber",0)
            elseif button == 4 then 
                ply:SetNWInt("ChairWireNumber",0)
            elseif button == 5 then 
                ply:SetNWInt("ChairWireNumber",0)
            elseif button == 6 then 
                ply:SetNWInt("ChairWireNumber",0)
            elseif button == 7 then 
                ply:SetNWInt("ChairWireNumber",0)
            elseif button == 8 then 
                ply:SetNWInt("ChairWireNumber",0)
            elseif button == 9 then 
                ply:SetNWInt("ChairWireNumber",0)
            elseif button == 10 then 
                ply:SetNWInt("ChairWireNumber",0)
            elseif button == 11 then 
                ply:SetNWInt("ChairWireNumber",0)
            end

            if CLIENT and not IsFirstTimePredicted() then
                return
            end
        else return end
    end)


    function ENT:Think()
        local curTime = CurTime()
        if curTime >= self.LastCheckTime + 1 then
            -- Run the player detection code every 1 second
            local radius = 128
            local foundPlayer = false
            
            local entities = ents.FindInSphere(self:GetPos(), radius)
            
            for _, ent in ipairs(entities) do
                if IsValid(ent) and ent:IsPlayer() then
                    if self.RequireATAGene and StarGate.HasATA(ent,false) == false then
                        continue
                    end
                    
                    if self.ShouldConsume and self:GetResource("energy") < 200 then
                        continue
                    end
                    
                    self.PlayerTouching = ent
                    self:SetWire("LitUp", 1)
                    self.PlayerTouching:SetNWInt("chair_initialized", 1)
                    
                    if not self.firstsound then
                        self:EmitSound("chair_sound_v2", 100, 10, 1)
                        self:EmitSound(self.Sounds.Activate2, 120, 70)
                        self:EmitSound(self.Sounds.Activate2, 120, 70)
                        self.firstsound = true
                    end
    
                    if self.Antarticatype then
                        self:SetSkin(4)
                    else
                        self:SetSkin(1)
                    end
                    
                    self.ChairActive = true
                    self.Touching = true
                    foundPlayer = true
                    break
                end
            end
            if not foundPlayer then

                self.Touching = false
                self.firstsound = false
            end
            
            self.LastCheckTime = curTime
        end


        if (IsValid(self.Pilot)) then
            umsg.Start("ControlChair", self.Pilot)
            umsg.Bool(self.Controlling)
            umsg.Bool(self.Enabled)
            umsg.Short(self.DroneCount)
            umsg.Entity(self.Chair)
            umsg.End()
        end

        if (self.ShieldActive) then
            if (self.ShouldConsume) then   -- AGP: was "not StarGate.LifeSupportAndWire == nil" (never true): the shield was free
            	if (self:GetResource("energy") < 100) then
                    self:SetNetworkedBool("Shield_online",false)
            		self.Entity:RemoveShield()
            		self:StopSound("tech/asgard_holo_loop.wav")
            	end
            	self:ConsumeResource("energy", 3000 * FrameTime())   -- AGP: 3000 a second (this runs every tick)
            end
        end

        if (self.ChairActive == false) then
        	self:StopSound("tech/asgard_holo_loop.wav")
        end


        if (self.ChairActive) then
            if (self.ShouldConsume) then
                if (self:GetResource("energy") < 100) then
                    self:Anims("close")
                    if (self.Shield and self.Shield:IsValid()) then
                        self.Entity:RemoveShield()
                    end   
                    self.ActiveTime = 180
                    if (self.Controlling) then
                        self.Pilot:SetNetworkedBool("Control",false)
                    	self:EmitSound(self.Sounds.Deactivate2, 100, 120)
                    self:EmitSound(self.Sounds.Deactivate2, 100, 120)
                    	self.PlayerTouching:SetNWInt("chair_initialized", 0)
                        self:DeactivateChair(self.Pilot)
                        self:StopSound("tech/asgard_holo_loop.wav")
                        self:EmitSound(self.Sounds.Deactivate, 100, 60)
                        self:EmitSound(self.Sounds.Deactivate, 100, 60)
                        self:EmitSound(self.Sounds.Deactivate, 100, 60)
                 		self:StopSound("thrusters/hover01.wav")
                    end

                    self:SetWire("Active", 0)
                    self:SetWire("LitUp", 0)

                    if (self.Antarticatype) then
            		self:SetSkin(3)
            	else
                	self:SetSkin(0)
                end
                    return
                end

                self:ConsumeResource("energy", 300)
            end
        end

        if (self.Controlling) then
            if (self.Enabled) then
                self:SetWire("Active", 1)

                if (self.RotateIsOn) then
                    self.RotationSpeed = math.Clamp(self.RotationSpeed + 0.01, 0, 0.3)
                else
                    self.RotationSpeed = math.Clamp(self.RotationSpeed - 0.01, 0, 0.3)
            	end

                if (self.RotationSpeed >0) then
                local a = self.Chair:GetAngles()
                    a:RotateAroundAxis(self:GetUp(), self.RotationSpeed)
                    self.Chair:SetAngles(a)
                end

                self:ConsumeResource("energy", 200)

            end
        end

        if (self.Controlling and IsValid(self.Pilot)) then
            if (self.Pilot:KeyDown(IN_FORWARD)) then
                if (self.Enabled) then
                    self:StopSound("thrusters/hover01.wav")
                 	self:StopSound("thrusters/hover01.wav")
                 	self:StopSound("thrusters/hover01.wav")
                    self.RotationSpeed = 0
                	if (self.Antarticatype) then
    				self.Chair:SetSkin(2)
    				else
        			self.Chair:SetSkin(0)
        			end
                    self.Pilot:SetNWInt("chair_initialized", 1)
                    self.Pilot:SetNetworkedBool("Control",false)
                	self:EmitSound(self.Sounds.Deactivate2, 100, 120)
                    self:EmitSound(self.Sounds.Deactivate2, 100, 120)
                    self:Anims("close")
                    self:SetWire("Active", 0)
                end
            elseif (self.Pilot:KeyDown(IN_BACK)) then
                if (not (self.Enabled)) then
                    self.Pilot:SetNWInt("chair_initialized", 2)
                	if (self.Antarticatype) then
    				self.Chair:SetSkin(3)
    				else
        			self.Chair:SetSkin(1)
        			end
                    self.Pilot:SetNetworkedBool("Control",true)
                    self:EmitSound(self.Sounds.Activate, 100, 100)
                    self:EmitSound(self.Sounds.Activate, 100, 100)
                    
                    self:Anims("open")
                    self:ConsumeResource("energy", 6000)
                end
            elseif (self.Pilot:KeyPressed(IN_MOVERIGHT)) then
                if (self.Pressed == false) then
                    self.Pressed = true
                	if (not self.Shield and self.StrengthShield == 100) then
                        self.Shield = self.Entity:SpawnShield()
                        self:SetNetworkedBool("Shield_online",true)
                    elseif (self.Shield and self.Shield:IsValid()) then
                        self:SetNetworkedBool("Shield_online",false) 
                        self.Entity:RemoveShield() 
                    end
                    timer.Simple(1, function() self.Pressed = false end)
                end
            elseif (self.Pilot:KeyPressed(IN_RELOAD) and self.Enabled) then
                 	if ( not self.RotateIsOn) then
                 		self.RotateIsOn = true
                        self:SetNetworkedBool("Rotate",true)
                 	else
                 		self.RotateIsOn = false
                        self:SetNetworkedBool("Rotate",false)
                 	end
            elseif (self.Pilot:KeyPressed(IN_JUMP) and self.Enabled) then
            		self:EmitSound("thrusters/hover01.wav",100,80)
            		self:EmitSound("ambient/explosions/exp2.wav",100,80)
            elseif (self.Pilot:KeyDown(IN_JUMP) and self.Enabled) then

            		self:ConsumeResource("energy", 5000)        		
            elseif (self.Pilot:KeyReleased(IN_JUMP) and self.Enabled) then
            		self:EmitSound("tech/hover01_end2.wav",100,80)
                 	self:StopSound("thrusters/hover01.wav")
                 	self:StopSound("thrusters/hover01.wav")
                 	self:StopSound("thrusters/hover01.wav")
            end
        end

        hook.Add( "PlayerButtonDown", "ControlChair_TargetMenu", function( ply, button )
        	if (self.Controlling and IsValid(self.Pilot) and self.Pilot == ply) then
				if (button == KEY_1 and not self.PilotViewing) then   -- AGP: key 1 = target list (was a debug-only class field)
                    self:SendTargetList(ply)
				end
			end
		end)

        hook.Add( "PlayerButtonDown", "ControlChair_interact_on", function( ply, button )
            if (self.Controlling and IsValid(self.Pilot) and self.Pilot == ply) then
                if (button == 13) then
                    ply:SetNWBool("Chair_viewing",true)
                    self.PilotViewing = true
                    SendMessageToClient(self.Pilot, self, "controlchair_interact",true)
                end
            end
        end)
        hook.Add( "PlayerButtonUp", "ControlChair_interact_off", function( ply, button )
            if (self.Controlling and IsValid(self.Pilot) and self.Pilot == ply) then
                if (button == 13) then
                    self.PilotViewing = false
                    ply:SetNWBool("Chair_viewing",false)
                    SendMessageToClient(self.Pilot, self, "controlchair_interact",false)
                end
            end
        end)


        -- Click functions wiremod


        ----------------------

        if (self.ShouldConsume) then
            if (self:GetResource("energy") < 500) then
                if (self.Controlling) then
                    self:Anims("close")
                    if (self.Shield and self.Shield:IsValid()) then
                        self.Entity:RemoveShield()
                    end            
                    self:DeactivateChair(self.Pilot)
                    self.Pilot:SetNWInt("chair_initialized", 0)
                    if (self.Antarticatype) then
            			self:SetSkin(3)
            		else
                		self:SetSkin(0)
                	end
                    self:SetWire("LitUp", 0)
                    self:StopSound("tech/asgard_holo_loop.wav")
                    self:EmitSound(self.Sounds.Deactivate, 100, 60)
                    self:EmitSound(self.Sounds.Deactivate, 100, 60)
                    self:EmitSound(self.Sounds.Deactivate, 100, 60)
                 	self:StopSound("thrusters/hover01.wav")
                end
            end
        end

        if (self.ChairActive) then
            if (not (self.Controlling)) then
                self.ActiveTime = math.Approach(self.ActiveTime, 180, 10)

            end
        end

        if (self.Controlling) then
            self:ConsumeResource("energy", 200)

            if (self:GetSkin() < 1) then
                self:SetSkin(1)
            end
        end

        if (self.Controlling and IsValid(self.Pilot)) then
            if (AGP.KeyPressIN(self, self.Pilot, IN_USE)) then -- AGP: a new press (E still held from sitting down no longer throws you out)
                if (self.NextUse < CurTime()) then
                    if self.Enabled then
                        self:Anims("close")
                    end

                    self:SetWire("Active", 0)
                    self.Pilot:SetNetworkedBool("Control",false)
                    self:EmitSound(self.Sounds.Deactivate, 100, 90)
                    self:EmitSound(self.Sounds.Deactivate, 100, 90)
                    self:EmitSound(self.Sounds.Deactivate, 100, 90)
                 	self:StopSound("thrusters/hover01.wav")

                    if (self.Controlling) then
                        self:DeactivateChair(self.Pilot)
                    end
                end
            end
        end

        if (self.ActiveTime) >= 180 then
            if ((not (self.Touching)) and (not (self.Controlling))) then
            	self.PlayerTouching:SetNWInt("chair_initialized", 0)
            	if (self.Antarticatype) then
            		self:SetSkin(3)
            	else
                	self:SetSkin(0)
                end
                self:StopSound("tech/asgard_holo_loop.wav")
                self:EmitSound(self.Sounds.Deactivate, 100, 70)
                self:EmitSound(self.Sounds.Deactivate, 100, 70)
                self:EmitSound(self.Sounds.Deactivate, 100, 70)
                firstsound = false
                self:SetWire("LitUp", 0)
                self.ChairActive = false
                self.ActiveTime = 0
            end
        end

        if (IsValid(self.Pilot)) then
            if (self.Controlling) then
                if (IsValid(self.ZpmHub)) then
                self:SetNetworkedString("ZPM_Online",self.ZpmHub.ZPM_Active)
                self:SetNetworkedInt("ZPM_Percentage",self.ZpmHub.ZPM_Percentage)
                end

                self:ConsumeResource("energy", 5 * self.DroneCount)
            	self.Track = true
                -- AGP: left mouse = a volley: a click fires 1 drone, holding fires up to 6 one after another
                -- (own edge detection: KeyPressed in Think can miss a short click)
                local fireDown = self.Pilot:KeyDown(IN_ATTACK) and self.Enabled and not self.PilotViewing
                if (fireDown) then
                    self:AGPFireThink(not self.AGPFireHeld)
                end
                self.AGPFireHeld = fireDown

                if (self.Pilot:KeyPressed(IN_ATTACK)) then
                    if (self.PilotViewing and self.Debug) then
                        SendMessageToClient(self.Pilot,self,"controlchair_click")
                    end
                end
                if (self.Pilot:KeyDown(IN_ATTACK2)) then
                    self:SetWire("Secondary", 1)
                    self:Targetlist()
                    -- AGP: right mouse (new press) = target list for automatic firing (not while flying a drone)
                    if (not self.AGPAltHeld and not self.PilotViewing and not self:AGPManualActive()) then
                        self:SendTargetList(self.Pilot)
                    end
                    self.AGPAltHeld = true
                else
                    self:SetWire("Secondary", 0)
                    self.AGPAltHeld = false
                end
            else
            	self.Track = false
            end
        end

        self:AGPManualThink() -- AGP: drone camera safety checks (lead gone, pilot dead / gone / out of the chair)

        self.FirePos = Vector(self.StartPos.X, self.StartPos.Y, self.StartPos.Z)

        self:UpdateWireEntTarget() -- AGP: wired entity has the highest target priority

        -- fix: update the outputs before the early return, they were frozen while someone sat in the chair.
        -- A copy of the vector, so wire sees a change when self.Target is modified in place.
        if (self.Target) then
            self:SetWire("X", self.Target.x)
            self:SetWire("Y", self.Target.y)
            self:SetWire("Z", self.Target.z)
            self:SetWire("Vector", Vector(self.Target.x, self.Target.y, self.Target.z))
        end

        if (self.Nextthink) then
            self:NextThink(CurTime())

            return true
        end
    end

    --######### Fire aVoN's type of drones @RononDex
    function ENT:FireDrones()
        if (self.DroneCount < 16) then
                
            local vel = self:GetVelocity()
            --calculate the drone's position offset. Otherwise it might collide with the launcher
            local e = ents.Create("drone")
            e.Parent = self
            e:SetPos(self.FirePos)
            e:SetAngles(Angle(-90, 0, 0))
            e:SetOwner(self) -- Don't collide with this thing here please
            e.Owner = self.Owner
            e:Spawn()
            e:SetVelocity(vel)
            self.DroneCount = self.DroneCount + 1
            self.Drones[e] = true
            self.Drone = e
            return e
        end
    end

    --######### AGP: drone volleys from the chair
    -- Left mouse starts a volley: a click fires 1 drone, holding fires up to VolleySize, one every VolleyInterval.
    -- Target locked (target list / Wire "Entity") or a wired position: the drones home in by themselves (self.Target).
    -- Nothing locked: hand-flown. The first drone is the lead: the pilot sees from it (client CalcView, NW2 entity
    -- "AGP_ChairLead") and it turns smoothly toward where he looks at a constant speed; the other drones of the volley
    -- follow it and, once it hits, fly into whatever it hit. The server owns all steering (drone.lua AGPGetTarget).
    ENT.VolleySize = 6
    ENT.VolleyInterval = 0.2
    ENT.ManualDroneSpeed = 2200 -- hand-flown drones (normal drones: up to 6000)
    ENT.ManualDroneFuel = 40000 -- their range in units (normal: 20000)

    function ENT:AGPManualActive()
        local v = self.AGPVolley
        return (v and v.manual and not v.released and IsValid(v.lead) and not v.lead.AGPFinished) and true or false
    end

    -- drone camera on / off for the pilot
    function ENT:AGPSetLeadView(lead)
        self:AGPClearView()
        if (IsValid(lead) and IsValid(self.Pilot)) then
            self.Pilot:SetNW2Entity("AGP_ChairLead", lead)
            self.AGPViewPly = self.Pilot
        end
    end

    function ENT:AGPClearView()
        if (IsValid(self.AGPViewPly)) then self.AGPViewPly:SetNW2Entity("AGP_ChairLead", NULL) end
        self.AGPViewPly = nil
    end

    -- camera back to the chair, the lead stops following the mouse (flies straight on)
    function ENT:AGPEndManual()
        self:AGPClearView()
        if (self.AGPVolley) then self.AGPVolley.released = true end
    end

    -- every Think: the camera always comes back (lead gone / hit, pilot dead, gone or out of the chair)
    function ENT:AGPManualThink()
        if (self.AGPViewPly == nil) then return end
        local ply = self.AGPViewPly
        if (not IsValid(ply) or not ply:Alive() or ply ~= self.Pilot or not self.Controlling or not self:AGPManualActive()) then
            self:AGPEndManual()
        end
    end

    function ENT:AGPFireThink(newPress)
        local now = CurTime()
        if (table.Count(self.RegisteredLaunchers) == 0) then
            if (now > (self.NextFire or 0) and IsValid(self.Pilot)) then
                AGP.SayAs(self.Pilot, "error", "agp_chair_nolaunchers", "No launchers linked! Touch the chair with a drone launcher to link it.")
                self.Pilot:EmitSound("buttons/button8.wav",100,100)
                self.NextFire = now + 1 -- wait a second before allowing to fire again
            end
            return
        end
        -- a new click starts a new volley; while a hand-flown lead is in the air the click adds to its volley instead
        if (newPress and not self:AGPManualActive()) then
            self.AGPVolley = { manual = not self:HasWiredTarget(), count = 0, nextShot = 0, speed = self.ManualDroneSpeed }
        end
        local v = self.AGPVolley
        if (not v or v.count >= self.VolleySize or now < v.nextShot) then return end
        local e = self:FireDrones()
        if (not IsValid(e)) then return end -- 16 drones in the air already
        v.count = v.count + 1
        v.nextShot = now + self.VolleyInterval
        if (v.manual) then self:AGPSetupManualDrone(v, e) end
    end

    function ENT:AGPSetupManualDrone(v, e)
        local chair = self
        e.MaxVelocity = v.speed
        e.Fuel = self.ManualDroneFuel
        e.AGPSweep = true -- hits walls, props, players and NPCs along its path
        if (v.lead == nil and not v.released) then
            v.lead = e
            e.TrackStart = 0.5                          -- under control quickly
            e.Randomness, e.AntiRandomness = 0.3, 0.7   -- smooth turns (normal drones: 0.6-0.9)
            e.AGPGetTarget = function(d)
                if (v.released or not IsValid(chair) or not chair.Controlling) then return nil end
                local ply = chair.Pilot
                if (not IsValid(ply) or not ply:Alive()) then return nil end
                return d:GetPos() + ply:GetAimVector() * 5000, true
            end
            e.AGPOnDone = function(d, pos, ent)
                v.leadDone = true
                v.hitPos = pos
                v.hitEnt = (IsValid(ent) and not ent:IsWorld()) and ent or nil
                if (IsValid(chair) and IsValid(chair.AGPViewPly) and chair.AGPViewPly:GetNW2Entity("AGP_ChairLead") == d) then
                    chair:AGPClearView()
                end
            end
            self:AGPSetLeadView(e)
        else
            e.AGPGetTarget = function(d)
                local lead = v.lead
                if (IsValid(lead) and not lead.AGPFinished) then
                    -- chase a point just ahead of the lead; catch up when far behind, then keep its speed
                    if (d.CanTrack) then
                        local spd = (d:GetPos():DistToSqr(lead:GetPos()) > 360000) and v.speed * 1.35 or v.speed
                        d.MaxVelocity, d.CurrentVelocity = spd, spd
                    end
                    local lv = lead:GetVelocity()
                    if (lv:LengthSqr() < 100) then lv = lead:GetForward() * v.speed end
                    return lead:GetPos() + lv * 0.3, true
                end
                if (d.CanTrack) then d.MaxVelocity, d.CurrentVelocity = v.speed * 1.5, v.speed * 1.5 end
                if (IsValid(v.hitEnt)) then return v.hitEnt:LocalToWorld(v.hitEnt:OBBCenter()), false end
                return v.hitPos, false -- nil (lead ran out of fuel): fly straight on
            end
        end
    end

    -- the area around the hand-flown drone must reach the pilot's game, the view entity is still the chair
    hook.Add("SetupPlayerVisibility", "AGP.ControlChairDroneCam", function(ply)
        local lead = ply:GetNW2Entity("AGP_ChairLead")
        if (IsValid(lead)) then AddOriginToPVS(lead:GetPos()) end
    end)
    hook.Add("PlayerDeath", "AGP.ControlChairDroneCam", function(ply)
        if (IsValid(ply)) then ply:SetNW2Entity("AGP_ChairLead", NULL) end
    end)

    --###### Dummy function for drones
    function ENT:ShowOutput()
    end

    --#########Add the wire inputs @ RononDex
    function ENT:TriggerInput(k, v)
        -- AGP: X / Y / Z build a new vector (no vector is changed in place) and are remembered in self.WireTarget;
        -- while a wired entity is valid it keeps priority (self.Target is only updated when no entity is wired)
        local base = self.WireTarget or self.Target or Vector(0, 0, 0)
        local wired = false
        if (not self.EyeTrack and k == "X") then
            self.PositionSet = true
            self.WireTarget = Vector(v, base.y, base.z)
            wired = true
        elseif (not self.EyeTrack and k == "Y") then
            self.PositionSet = true
            self.WireTarget = Vector(base.x, v, base.z)
            wired = true
        elseif (not self.EyeTrack and k == "Z") then
            self.PositionSet = true
            self.WireTarget = Vector(base.x, base.y, v)
            wired = true
        end

        if (k == "Vector") then
            self.WireTarget = Vector(v.x, v.y, v.z) -- fix: copy, so the X/Y/Z inputs never change the wired vector in place
            wired = true
        end

        if (wired and not IsValid(self.WireEnt)) then
            self.Target = Vector(self.WireTarget.x, self.WireTarget.y, self.WireTarget.z)
        end

        if (k == "Entity") then
            self.WireEnt = v -- AGP: was declared but never handled; UpdateWireEntTarget uses it every Think
            self:UpdateWireEntTarget()
        end

        if (k == "Start X") then
            self.StartPos.X = v
        elseif (k == "Start Y") then
            self.StartPos.Y = v
        elseif (k == "Start Z") then
            self.StartPos.Z = v
        end
    end

    function ENT:Anims(anim)
        if (IsValid(self) and IsValid(self.Chair)) then
            if self.Enabled and anim == "open" then return end

            if not self.Enabled and anim == "close" then return end

            if (anim == "close") then
                anim = "open"
                self:Lean(false)
                self.Enabled = false
            elseif (anim == "open") then
                anim = "close"
                self:Lean(true)
                self.Enabled = true
            end
            self.Anim = self.Chair:LookupSequence(anim)
            self.Chair:ResetSequenceInfo()
            self.Chair:SetSequence(self.Anim)
        end
    end


    function ENT:Lean(active)
        local pelvis = "ValveBiped.Bip01_Pelvis"
        local L_thigh = "ValveBiped.Bip01_L_Thigh"
        local R_thigh = "ValveBiped.Bip01_R_Thigh"
        local L_calf = "ValveBiped.Bip01_L_Calf"
        local R_calf = "ValveBiped.Bip01_R_Calf"

        local L_upperarm = "ValveBiped.Bip01_L_UpperArm"
        local R_upperarm = "ValveBiped.Bip01_R_UpperArm"
        local L_forarm = "ValveBiped.Bip01_L_Forearm"
        local R_forarm = "ValveBiped.Bip01_R_Forearm"


        if (active) then
            
            local bonetomove = self.Ragdoll:LookupBone(pelvis)
            if bonetomove then
                self.Ragdoll:ManipulateBoneAngles(bonetomove, Angle(0, 0, -30))  -- Tilt the pelvis backward
            end

            local bonetomove = self.Ragdoll:LookupBone(L_thigh)
            if bonetomove then
                self.Ragdoll:ManipulateBoneAngles(bonetomove, Angle(0, -60, 0))  -- Tilt the pelvis backward
            end

            local bonetomove = self.Ragdoll:LookupBone(R_thigh)
            if bonetomove then
                self.Ragdoll:ManipulateBoneAngles(bonetomove, Angle(0, -60, 0))  -- Tilt the pelvis backward
            end

            local bonetomove = self.Ragdoll:LookupBone(L_calf)
            if bonetomove then
                self.Ragdoll:ManipulateBoneAngles(bonetomove, Angle(0, 50, 0))  -- Tilt the pelvis backward
            end

            local bonetomove = self.Ragdoll:LookupBone(R_calf)
            if bonetomove then
                self.Ragdoll:ManipulateBoneAngles(bonetomove, Angle(0, 50, 0))  -- Tilt the pelvis backward
            end
            
            local bonetomove = self.Ragdoll:LookupBone(L_upperarm)
            if bonetomove then
                self.Ragdoll:ManipulateBoneAngles(bonetomove, Angle(0, -15, 0))  -- Tilt the pelvis backward
            end

            local bonetomove = self.Ragdoll:LookupBone(R_upperarm)
            if bonetomove then
                self.Ragdoll:ManipulateBoneAngles(bonetomove, Angle(0, -15, 0))  -- Tilt the pelvis backward
            end

            local bonetomove = self.Ragdoll:LookupBone(L_forarm)
            if bonetomove then
                self.Ragdoll:ManipulateBoneAngles(bonetomove, Angle(0, -75, 0))  -- Tilt the pelvis backward
                self.Ragdoll:ManipulateBonePosition(bonetomove, Vector(8,8 , 0),true)
            end

            local bonetomove = self.Ragdoll:LookupBone(R_forarm)
            if bonetomove then
                self.Ragdoll:ManipulateBoneAngles(bonetomove, Angle(0, -75, 0))  -- Tilt the pelvis backward
                self.Ragdoll:ManipulateBonePosition(bonetomove, Vector(8,8 , 0),true)
            end

        else

            local bonetomove = self.Ragdoll:LookupBone(pelvis)
            if bonetomove then
                self.Ragdoll:ManipulateBoneAngles(bonetomove, Angle(0, 0,0 ))  -- Tilt the pelvis backward
            end

            local bonetomove = self.Ragdoll:LookupBone(L_thigh)
            if bonetomove then
                self.Ragdoll:ManipulateBoneAngles(bonetomove, Angle(0, -90, 0))  -- Tilt the pelvis backward
            end

            local bonetomove = self.Ragdoll:LookupBone(R_thigh)
            if bonetomove then
                self.Ragdoll:ManipulateBoneAngles(bonetomove, Angle(0, -90, 0))  -- Tilt the pelvis backward
            end

            local bonetomove = self.Ragdoll:LookupBone(L_calf)
            if bonetomove then
                self.Ragdoll:ManipulateBoneAngles(bonetomove, Angle(0, 90, 0))  -- Tilt the pelvis backward
            end

            local bonetomove = self.Ragdoll:LookupBone(R_calf)
            if bonetomove then
                self.Ragdoll:ManipulateBoneAngles(bonetomove, Angle(0, 90, 0))  -- Tilt the pelvis backward
            end

            local bonetomove = self.Ragdoll:LookupBone(L_upperarm)
            if bonetomove then
                self.Ragdoll:ManipulateBoneAngles(bonetomove, Angle(0, -35, 0))  -- Tilt the pelvis backward
            end

            local bonetomove = self.Ragdoll:LookupBone(R_upperarm)
            if bonetomove then
                self.Ragdoll:ManipulateBoneAngles(bonetomove, Angle(0, -35, 0))  -- Tilt the pelvis backward
            end

            local bonetomove = self.Ragdoll:LookupBone(L_forarm)
            if bonetomove then
                self.Ragdoll:ManipulateBoneAngles(bonetomove, Angle(0, -55, 0))  -- Tilt the pelvis backward
                self.Ragdoll:ManipulateBonePosition(bonetomove, Vector(4,4 , 0),true)
            end

            local bonetomove = self.Ragdoll:LookupBone(R_forarm)
            if bonetomove then
                self.Ragdoll:ManipulateBoneAngles(bonetomove, Angle(0, -55, 0))  -- Tilt the pelvis backward
                self.Ragdoll:ManipulateBonePosition(bonetomove, Vector(4,4 , 0),true)
            end

        end
    end


--####### Spawn the ragdoll @RononDex
function ENT:SpawnRagdoll()

	if(IsValid(self)) then
		if(IsValid(self.Pilot)) then

        local offset = Vector(7.5, 0, -15)
        local chairAngles = self.Chair:GetAngles()
        
        -- Convert angles to radians
        local radPitch = math.rad(chairAngles.p)
        local radYaw = math.rad(chairAngles.y)
        local radRoll = math.rad(chairAngles.r)

        -- Calculate rotated offset
        local rotatedOffset = Vector(
            offset.x * math.cos(radYaw) - offset.y * math.sin(radYaw),
            offset.x * math.sin(radYaw) + offset.y * math.cos(radYaw),
            offset.z
        )

			local e = ents.Create("prop_dynamic")
			e:SetModel(self.Pilot:GetModel())
			e:SetPos(self.Chair:GetPos() + rotatedOffset)
			e:SetAngles(self.Chair:GetAngles()+Angle(0,180,0))

			e:Spawn()
			e:Activate()
			e:SetParent(self.Chair)

			self.Ragdoll=e
            
            local L_thigh = "ValveBiped.Bip01_L_Thigh"
            local R_thigh = "ValveBiped.Bip01_R_Thigh"
            local L_calf = "ValveBiped.Bip01_L_Calf"
            local R_calf = "ValveBiped.Bip01_R_Calf"
            local L_upperarm = "ValveBiped.Bip01_L_UpperArm"
            local R_upperarm = "ValveBiped.Bip01_R_UpperArm"
            local L_forarm = "ValveBiped.Bip01_L_Forearm"
            local R_forarm = "ValveBiped.Bip01_R_Forearm"
            
            local bonetomove = self.Ragdoll:LookupBone(L_thigh)
            if bonetomove then
                self.Ragdoll:ManipulateBoneAngles(bonetomove, Angle(0, -90, 0))  -- Tilt the pelvis backward
            end

            local bonetomove = self.Ragdoll:LookupBone(R_thigh)
            if bonetomove then
                self.Ragdoll:ManipulateBoneAngles(bonetomove, Angle(0, -90, 0))  -- Tilt the pelvis backward
            end

            local bonetomove = self.Ragdoll:LookupBone(L_calf)
            if bonetomove then
                self.Ragdoll:ManipulateBoneAngles(bonetomove, Angle(0, 90, 0))  -- Tilt the pelvis backward
            end

            local bonetomove = self.Ragdoll:LookupBone(R_calf)
            if bonetomove then
                self.Ragdoll:ManipulateBoneAngles(bonetomove, Angle(0, 90, 0))  -- Tilt the pelvis backward
            end

            local bonetomove = self.Ragdoll:LookupBone(L_upperarm)
            if bonetomove then
                self.Ragdoll:ManipulateBoneAngles(bonetomove, Angle(0, -35, 0))  -- Tilt the pelvis backward
            end

            local bonetomove = self.Ragdoll:LookupBone(R_upperarm)
            if bonetomove then
                self.Ragdoll:ManipulateBoneAngles(bonetomove, Angle(0, -35, 0))  -- Tilt the pelvis backward
            end

            local bonetomove = self.Ragdoll:LookupBone(L_forarm)
            if bonetomove then
                self.Ragdoll:ManipulateBoneAngles(bonetomove, Angle(0, -55, 0))  -- Tilt the pelvis backward
                self.Ragdoll:ManipulateBonePosition(bonetomove, Vector(4,4 , 0),true)
            end

            local bonetomove = self.Ragdoll:LookupBone(R_forarm)
            if bonetomove then
                self.Ragdoll:ManipulateBoneAngles(bonetomove, Angle(0, -55, 0))  -- Tilt the pelvis backward
                self.Ragdoll:ManipulateBonePosition(bonetomove, Vector(4,4 , 0),true)
            end

		end
	end
end

--############## This is what puts the ragdoll into the right pose @RononDex
    function ENT:RagdollPose()


    	local chest = self.Ragdoll:GetPhysicsObjectNum(1)
    	chest:SetPos(self.Chair:GetPos()+self.Chair:GetUp()*290)


    	chest:SetAngles(self:GetAngles()+Angle(0,-45,0))
    	chest:SetAngles(self.Chair:GetAngles())

    	local pelvis = self.Ragdoll:GetPhysicsObjectNum(0)
    	pelvis:SetPos(self.Chair:GetPos())

    	local lthigh = self.Ragdoll:GetPhysicsObjectNum(11)
    	lthigh:SetPos(self.Chair:GetPos()+self:GetRight()*-10+self:GetUp()*25)

    	local lfoot = self.Ragdoll:GetPhysicsObjectNum(13)

    	local rfoot = self.Ragdoll:GetPhysicsObjectNum(14)
    end

    function ENT:LookupBones()
        local bones = self.Ragdoll:LookupBone("ValveBiped.Bip01_L_Foot")
    end

    
    function ENT:PostEntityPaste(ply, Ent, CreatedEntities)
        if (StarGate.NotSpawnable(Ent:GetClass(), ply)) then
            self.Entity:Remove()

            return
        end

        self:AddChair(ply)
        self:AddZPMHub()
        StarGate.WireRD.PostEntityPaste(self, ply, Ent, CreatedEntities)
    end

    if (StarGate and StarGate.CAP_GmodDuplicator) then
        duplicator.RegisterEntityClass("control_chair", StarGate.CAP_GmodDuplicator, "Data")
    end
end


properties.Add( "Stargate.Controlchair.DoAntartica",
{
	MenuLabel	=	"Toggle Type",
	Order		=	-100,
	MenuIcon	=	"icon16/plugin_go.png",

	Filter		=	function( self, ent, ply )
						if ( !IsValid( ent ) || !IsValid( ply )) then return false end
						if (ent:GetClass() ~= "control_chair") then return false end
						
						if (ent:GetClass()=="control_chair") then
						return true
					end

					end,

	Action		=	function( self, ent )
                        SendMessageToServer(self,ent,"ToggleChairMode",ent)				
						self:MsgEnd()
					end,

	Receive		=	function( self, length, player )

					end

});

properties.Add( "Stargate.Controlchair.DoAtlantis",
{
	MenuLabel	=	"Toggle Version",
	Order		=	-100,
	MenuIcon	=	"icon16/plugin_go.png",

	Filter		=	function( self, ent, ply )
						if ( !IsValid( ent ) || !IsValid( ply )) then return false end
						if (ent:GetClass() ~= "control_chair") then return false end
						
						if (ent:GetClass()=="control_chair") then
						return true
					end

					end,

	Action		=	function( self, ent )
                        SendMessageToServer(self,ent,"ToggleChairMode_Atlantis",ent)
						
							
						self:MsgEnd()
					end,

	Receive		=	function( self, length, player )

					end

});


if CLIENT then


    surface.CreateFont("Font", {
    font = "Arial",
    extended = true,
    size = 20
    })

    function TargetControlMenu(ent, targets)
        local faded_blue = (AGP and AGP.Colors and AGP.Colors.panel) or Color(0, 100, 180, 200) -- AGP: our look (was a bright blue)
        local Frame = vgui.Create("DFrame")
        if (AGP and AGP.ApplySkin) then AGP.ApplySkin(Frame) end -- AGP: our look
        Frame:SetPos(50, 50)
        Frame:SetSize(500, 750)
        Frame:SetTitle(AGP.L("agp_ui_chair_targets", "Control chair: targets"))
        Frame:SetVisible(true)
        Frame:SetDraggable(true)
        Frame:ShowCloseButton(true)
        Frame:MakePopup()

        local sheet = vgui.Create("DPropertySheet", Frame)
        sheet:Dock(FILL)

        local panel1 = vgui.Create("DPanel", sheet)
        panel1.Paint = function(self, w, h) draw.RoundedBox(4, 0, 0, w, h, faded_blue) end
        sheet:AddSheet("Target System", panel1, "icon16/asterisk_orange.png")

        local NameEntry = vgui.Create("DTextEntry", panel1)
        NameEntry:SetPos(25, 50)
        NameEntry:SetSize(85, 35)
        NameEntry:SetText(AGP.L("agp_ui_target_class", "Target class"))
        NameEntry.OnEnter = function(self)
            SendToChair(self:GetValue(), ent)
        end

        local panel2 = vgui.Create("DPanel", sheet)
        panel2.Paint = function(self, w, h) draw.RoundedBox(4, 0, 0, w, h, faded_blue) end
        sheet:AddSheet("Wiring", panel2, "icon16/bullet_wrench.png")

        local SheetItemTwo = vgui.Create("DCheckBoxLabel", panel2)
        SheetItemTwo:SetText(AGP.L("agp_ui_toggle_wire", "Wire on / off"))
        SheetItemTwo:SetConVar("CChair_togglewire")
        SheetItemTwo:SetValue(0)
        SheetItemTwo:SizeToContents()
    end


	function SendToChair (value, entity)

        SendMessageToServer(self, entity, "ControlChair_Relay_from_client_target",value )


	end
end

-- AGP: target list of the chair. Right mouse or key 1 in the chair: everything near it that drones can chase (players, NPCs,
-- vehicles and ships); "Lock on" makes the drones follow that target (like the Wire "Entity" input), "Free aim" ends it.
if SERVER then
    util.AddNetworkString("AGP_ChairTargets")
    util.AddNetworkString("AGP_ChairLock")
    ENT.TargetRange = 15000
    function ENT:SendTargetList(ply)
        local list = {}
        for _, e in ipairs(ents.FindInSphere(self:GetPos(), self.TargetRange)) do
            if (IsValid(e) and e ~= ply and (e:IsPlayer() and e:Alive() or e:IsNPC() or e:IsNextBot() or e:IsVehicle() or (e.Type == "vehicle" and e.Base == "sg_vehicle_base") or e:GetClass() == "agp_hatak")) then
                if (not (IsValid(e:GetParent()) and e:IsVehicle())) then list[#list + 1] = e end
            elseif (IsValid(e) and e:GetClass() == "prop_physics" and e ~= self.Chair and e ~= self.ZpmHub and not IsValid(e:GetParent())) then
                list[#list + 1] = e -- AGP: props too (listed after players, NPCs and ships)
            end
        end
        local here = self:GetPos()
        table.sort(list, function(a, b)
            local pa, pb = a:GetClass() == "prop_physics", b:GetClass() == "prop_physics"
            if (pa ~= pb) then return pb end
            return a:GetPos():DistToSqr(here) < b:GetPos():DistToSqr(here)
        end)
        local n = math.min(#list, 100)
        net.Start("AGP_ChairTargets")
        net.WriteEntity(self)
        net.WriteEntity(self.WireEnt or NULL)
        net.WriteUInt(n, 7)
        for i = 1, n do net.WriteEntity(list[i]) end
        net.Send(ply)
    end
    net.Receive("AGP_ChairLock", function(_, ply)
        local chair, target = net.ReadEntity(), net.ReadEntity()
        if (not IsValid(chair) or chair:GetClass() ~= "control_chair" or chair.Pilot ~= ply) then return end
        chair.WireEnt = IsValid(target) and target or nil   -- the drones' target, highest priority (UpdateWireEntTarget)
        if (IsValid(target)) then AGP.Say(ply, "agp_chair_locked", "Control chair: drones locked on %s", target:IsPlayer() and target:Nick() or (target.PrintName ~= "" and target.PrintName) or target:GetClass())
        else AGP.Say(ply, "agp_chair_freeaim", "Control chair: free aim") end
    end)
end

if CLIENT then
    net.Receive("AGP_ChairTargets", function()
        local chair, locked = net.ReadEntity(), net.ReadEntity()
        local list = {}
        for i = 1, net.ReadUInt(7) do list[i] = net.ReadEntity() end
        local function L(k, d) return AGP and AGP.L and AGP.L(k, d) or d end
        local fr = vgui.Create("DFrame")
        fr:SetTitle(L("agp_chair_targets", "Control chair: targets")); fr:SetSize(460, 420); fr:Center(); fr:MakePopup()
        if (AGP and AGP.ApplySkin) then AGP.ApplySkin(fr) end
        local lv = vgui.Create("DListView", fr)
        lv:Dock(FILL); lv:SetMultiSelect(false)
        lv:AddColumn(L("agp_chair_t_name", "Target")); lv:AddColumn(L("agp_chair_t_kind", "Kind")):SetFixedWidth(90); lv:AddColumn(L("agp_chair_t_dist", "Distance")):SetFixedWidth(90)
        for _, e in ipairs(list) do
            if (IsValid(e)) then
                local kind = e:IsPlayer() and L("agp_chair_k_player", "player") or ((e:IsNPC() or e:IsNextBot()) and L("agp_chair_k_npc", "NPC") or (e:GetClass() == "prop_physics" and L("agp_chair_k_prop", "prop") or L("agp_chair_k_ship", "ship / vehicle")))
                local name = e:IsPlayer() and e:Nick() or ((e.PrintName and e.PrintName ~= "") and e.PrintName or e:GetClass())
                local dist = AGP and AGP.Units and AGP.Units.Distance and AGP.Units.Distance(e:GetPos():Distance(chair:GetPos())) or math.Round(e:GetPos():Distance(chair:GetPos()))
                local line = lv:AddLine((e == locked and "> " or "") .. name, kind, dist)
                line.AGPTarget = e
            end
        end
        local bar = vgui.Create("DPanel", fr); bar:Dock(BOTTOM); bar:SetTall(36); bar.Paint = nil
        local lock = vgui.Create("DButton", bar); lock:Dock(LEFT); lock:SetWide(210); lock:SetText(L("agp_chair_lock", "Lock on"))
        lock.DoClick = function()
            local _, line = lv:GetSelectedLine()
            if (not line) then return end
            net.Start("AGP_ChairLock"); net.WriteEntity(chair); net.WriteEntity(line.AGPTarget); net.SendToServer(); fr:Close()
        end
        lv.DoDoubleClick = function(_, _, line) net.Start("AGP_ChairLock"); net.WriteEntity(chair); net.WriteEntity(line.AGPTarget); net.SendToServer(); fr:Close() end
        local free = vgui.Create("DButton", bar); free:Dock(RIGHT); free:SetWide(210); free:SetText(L("agp_chair_free", "Free aim"))
        free.DoClick = function() net.Start("AGP_ChairLock"); net.WriteEntity(chair); net.WriteEntity(NULL); net.SendToServer(); fr:Close() end
        if (#list == 0) then lv:AddLine(L("agp_chair_none", "Nothing in range"), "", "") end
    end)
end

