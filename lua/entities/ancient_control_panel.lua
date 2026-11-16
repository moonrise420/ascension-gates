--[[
	Ancient Console
	Copyright (C) 2011 Madman07
]]
--
if (StarGate ~= nil and StarGate.LifeSupportAndWire ~= nil) then
    StarGate.LifeSupportAndWire(ENT)
end

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Ancient Control Panel"
ENT.Author = "Madman07"
ENT.Category = "Ascension Gates"
ENT.WireDebugName = "Ancient Control Panel"
ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.AutomaticFrameAdvance = true
ENT.Untouchable = true

if SERVER then
    if (StarGate == nil or StarGate.CheckModule == nil or not StarGate.CheckModule("entweapon")) then return end
    AddCSLuaFile()

    ENT.Sounds = {
        PressOne = Sound("dakara/dakara_control_panel.wav"),
        PressFew = Sound("dakara/dakara_control_panel2.wav")
    }

    ENT.Anims = {"push1", "push2", "push3", "push4", "push5", "random", "reset", "crystalo", "crystalc"}

    -----------------------------------INIT----------------------------------
    function ENT:Initialize()
        util.PrecacheModel("models/Iziraider/dakara/console.mdl")
        self.Entity:SetModel("models/Iziraider/dakara/console.mdl")
        self.Entity:SetName("Ancient Control Console")
        self.Entity:PhysicsInit(SOLID_VPHYSICS)
        self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
        self.Entity:SetSolid(SOLID_VPHYSICS)
        self.Entity:SetUseType(SIMPLE_USE)
        self.CurrentOption = 0
        self.OpenCrystal = false
        self.Busy = false
        self.AlreadyOpened = false
        self.AnimRunning = false
        self.SlotOpen = false
        self.ATAMode = false
        self:CreateWireInputs("ATA Mode")
        
        -- Register the console command once during initialization
        concommand.Add("AP" .. self:EntIndex(), function(ply, cmd, args)
            -- fix: only the player who opened the menu, close to the console, and not while it is busy
            if (not IsValid(self) or not IsValid(ply) or ply ~= self.Player or not ply:Alive()) then return end
            if (ply:GetPos():Distance(self:GetPos()) > 400) then return end
            if (self.ATAMode and not StarGate.HasATA(ply, true)) then return end
            if (self.AnimRunning or self.Busy) then return end
            self.Player = nil -- one command per Use

            local power = math.Clamp(tonumber(args[1]) or 5, 0, 10)
            self.AnimRunning = true
            self:Anim(self.Anims[1], 0, false, self.Sounds.PressOne)
            self:Anim(self.Anims[2], 1.5, false, self.Sounds.PressOne)
            self:Anim(self.Anims[3], 3, false, self.Sounds.PressOne)
            self:Anim(self.Anims[4], 4.5, false, self.Sounds.PressOne)
            self:Anim(self.Anims[5], 6, false, self.Sounds.PressOne)
            self:Anim(self.Anims[6], 7.5 + power / 2, false, self.Sounds.PressFew)
            self:Anim(self.Anims[6], 11.5 + power / 2, false, self.Sounds.PressFew)
            self:Anim(self.Anims[7], 17.5 + power / 2, false, self.Sounds.PressOne)

            timer.Create("AGP.ACP.StopAnim" .. self:EntIndex(), 20 + power / 2, 1, function()
                if (IsValid(self)) then self.AnimRunning = false end
            end)

            local dakara = self:FindDakara()

            if (IsValid(dakara)) then
                -- fix: these were globals
                local target_players = tonumber(args[2]) or 0
                local target_props = tonumber(args[3]) or 0
                local target_vehicles = tonumber(args[4]) or 0
                local target_replicators = tonumber(args[5]) or 0
                local target_npcs = tonumber(args[6]) or 0
                local target_range = math.Clamp(tonumber(args[7]) or 15000, 5000, 18000)
                local dial_gates = tonumber(args[8]) or 0

                timer.Create("AGP.ACP.PrepareDakara" .. self:EntIndex(), 5 / 2, 1, function()
                if (IsValid(dakara)) then
                    dakara:PrepareWeapon(power, target_players, target_props, target_vehicles, target_replicators, target_npcs, target_range, dial_gates)
                end
                end)
                timer.Create("AGP.ACP.DialAllGates" .. self:EntIndex(), 1 / 2, 1, function()
                    if (dial_gates == 1 and IsValid(self) and IsValid(dakara)) then
                        self:DiallAllGates(dakara, dial_gates)
                    end
                end)
            end
        end)
    end

    -- fix: remove the console command and this panel's timers with the entity
    function ENT:OnRemove()
        local id = self:EntIndex()
        concommand.Remove("AP" .. id)
        if (timer.Exists("AGP.ACP.Autoclose" .. id)) then self:CloseDialledGates() end

        for _, name in pairs({"StopAnim", "PrepareDakara", "DialAllGates", "DialFrom", "DialTo", "Autoclose"}) do
            timer.Remove("AGP.ACP." .. name .. id)
        end

        for _, anim in pairs(self.Anims) do
            timer.Remove("AGP.ACP." .. anim .. id)
        end
    end

    function ENT:TriggerInput(k, v)
        if(k == "ATA Mode") then
            if(v > 0) then
                self.ATAMode = true 
            else
                self.ATAMode = false
            end
        end
    end

    -----------------------------------USE----------------------------------
    function ENT:Use(ply)
        if(self.ATAMode and not StarGate.HasATA(ply,true)) then return end
        
        if (not self.Busy) then
            umsg.Start("AncientPanel", ply)
            umsg.Entity(self.Entity)
            umsg.End()
            self.Player = ply
        end
    end

    -----------------------------------OTHER CRAP----------------------------------
    function ENT:UpdateTransmitState()
        return TRANSMIT_ALWAYS
    end

    --########## Run the anim that's set in the arguements @RononDex
    function ENT:Anim(anim, delay, nosound, sound)
        timer.Create("AGP.ACP." .. anim .. self:EntIndex(), delay, 1, function()
            if IsValid(self) then
                self:NextThink(CurTime())

                --Set false to allow sound
                if (not (nosound)) then
                    self:EmitSound(sound, 100, math.random(90, 110)) --create sound as a string in the arguements
                end

                self:SetPlaybackRate(1)
                self:ResetSequence(self:LookupSequence(anim)) -- play the sequence
            end
        end)
    end

    function ENT:Think()
        --run often only if doors are busy
        if self.AnimRunning then
            self:NextThink(CurTime())

            return true
        end
    end

    function ENT:DiallAllGates(dakara , dial_gates)
        self.DialGate = dakara:FindGate()

        if IsValid(self.DialGate) then
            self.IncomingGates = dakara:FindAllGate()
            self.DialGate.Target = self.DialGate
            self.DialGate:AbortDialling()

            for _, v in pairs(self.IncomingGates or {}) do
                v:AbortDialling()
            end

            timer.Create("AGP.ACP.DialFrom" .. self:EntIndex(), 2, 1, function()
                if (not IsValid(self) or not IsValid(self.DialGate)) then return end
                local action = self.DialGate.Sequence:New()
                action = self.DialGate.Sequence:Dial(false, true, false)
                action = action + self.DialGate.Sequence:OpenGate(true)
                self.DialGate:RunActions(action)
            end)

            timer.Create("AGP.ACP.DialTo" .. self:EntIndex(), 2.3, 1, function()
                if (not IsValid(self)) then return end
                for _, v in pairs(self.IncomingGates or {}) do
                    if v == self.DialGate or not IsValid(v) then continue end
                    v.Outbound = true -- fix lighting up dhds
                    local action = v.Sequence:New()
                    action = v.Sequence:Dial(true, true, false)
                    action = action + v.Sequence:OpenGate()
                    v:RunActions(action)
                end
            end)

            timer.Create("AGP.ACP.Autoclose" .. self:EntIndex(), 15, 1, function()
                if (IsValid(self)) then self:CloseDialledGates() end
            end)
        end
    end

    function ENT:CloseDialledGates()
        if (IsValid(self.DialGate)) then
            self.DialGate:EmergencyShutdown() -- different methods or gates wont close, hope it will work
            self.DialGate:AbortDialling()
            self.DialGate:DeactivateStargate(true)

            for _, v in pairs(self.IncomingGates or {}) do
                if IsValid(v) then
                    v:EmergencyShutdown()
                    v:AbortDialling()
                    v:DeactivateStargate(true)
                end
            end
        end
    end

    function ENT:FindDakara()
        local gate
        local dist = 10000000
        local pos = self.Entity:GetPos()

        for _, v in pairs(ents.FindByClass("dakara_building")) do
            local sg_dist = (pos - v:GetPos()):Length()

            if (dist >= sg_dist) then
                dist = sg_dist
                gate = v
            end
        end

        return gate
    end
end

if CLIENT then
    local e -- fix: the panel's entity was a client global
    function ENT:Draw()
        self.Entity:DrawModel()
    end

    local VGUI = {}

    function VGUI:Init()
        local DermaPanel = vgui.Create("DFrame")
        if (AGP and AGP.ApplySkin) then AGP.ApplySkin(DermaPanel) end -- AGP: our look
        DermaPanel:SetPos(ScrW() / 2 - 163.5, ScrH() / 2 - 227.5)
        DermaPanel:SetSize(400, 270)
        DermaPanel:SetTitle(AGP.L("agp_ui_dakara_title", "Dakara Device Control Panel"))
        DermaPanel:SetVisible(true)
        DermaPanel:SetDraggable(false)
        DermaPanel:ShowCloseButton(true)
        DermaPanel:MakePopup()

        DermaPanel.Paint = function()
            draw.RoundedBox(10, 0, 0, DermaPanel:GetWide(), DermaPanel:GetTall(), (AGP and AGP.Colors and AGP.Colors.bg) or Color(14, 20, 30, 245)) -- AGP: our look (was a grey box)
        end

        local NumSliderThingy2 = vgui.Create("DNumSlider", DermaPanel)
        NumSliderThingy2:SetPos(25, 180)
        NumSliderThingy2:SetSize(360, 50)
        NumSliderThingy2:SetText(AGP.L("agp_ui_dakara_power", "Faster - Stronger"))
        NumSliderThingy2:SetMin(-5)
        NumSliderThingy2:SetMax(5)
        NumSliderThingy2:SetValue(0)
        NumSliderThingy2:SetDecimals(2)
        NumSliderThingy2:SetToolTip(AGP.L("agp_ui_dakara_power_tip", "The device's power: it sets the radius and the charging time."))
        local CheckBoxThing1 = vgui.Create("DCheckBoxLabel", DermaPanel)
        CheckBoxThing1:SetPos(25, 30)
        CheckBoxThing1:SetText(AGP.L("agp_ui_dak_players", "Disintegrate players"))
        CheckBoxThing1:SetValue(1)
        CheckBoxThing1:SizeToContents()
        CheckBoxThing1:SetToolTip(AGP.L("agp_ui_dak_players_tip", "The wave disintegrates players."))
        local CheckBoxThing2 = vgui.Create("DCheckBoxLabel", DermaPanel)
        CheckBoxThing2:SetPos(25, 50)
        CheckBoxThing2:SetText(AGP.L("agp_ui_dak_props", "Disintegrate props"))
        CheckBoxThing2:SetValue(0)
        CheckBoxThing2:SizeToContents()
        CheckBoxThing2:SetToolTip(AGP.L("agp_ui_dak_props_tip", "The wave disintegrates props."))
        local CheckBoxThing3 = vgui.Create("DCheckBoxLabel", DermaPanel)
        CheckBoxThing3:SetPos(25, 70)
        CheckBoxThing3:SetText(AGP.L("agp_ui_dak_vehicles", "Disintegrate vehicles"))
        CheckBoxThing3:SetValue(0)
        CheckBoxThing3:SizeToContents()
        CheckBoxThing3:SetToolTip(AGP.L("agp_ui_dak_vehicles_tip", "The wave disintegrates vehicles."))
        local CheckBoxThing4 = vgui.Create("DCheckBoxLabel", DermaPanel)
        CheckBoxThing4:SetPos(200, 30)
        CheckBoxThing4:SetText(AGP.L("agp_ui_dak_reps", "Disintegrate Replicators"))
        CheckBoxThing4:SetValue(0)
        CheckBoxThing4:SizeToContents()
        CheckBoxThing4:SetToolTip(AGP.L("agp_ui_dak_reps_tip", "The wave disintegrates Replicators."))
        local CheckBoxThing5 = vgui.Create("DCheckBoxLabel", DermaPanel)
        CheckBoxThing5:SetPos(200, 50)
        CheckBoxThing5:SetText(AGP.L("agp_ui_dak_npcs", "Disintegrate NPCs"))
        CheckBoxThing5:SetValue(0)
        CheckBoxThing5:SizeToContents()
        CheckBoxThing5:SetToolTip(AGP.L("agp_ui_dak_npcs_tip", "The wave disintegrates NPCs."))

        
        local CheckBoxThing8 = vgui.Create("DCheckBoxLabel", DermaPanel)
        CheckBoxThing8:SetPos(25, 90)
        CheckBoxThing8:SetText(AGP.L("agp_ui_dak_dial", "Dial Stargates"))
        CheckBoxThing8:SetValue(0)
        CheckBoxThing8:SizeToContents()
        CheckBoxThing8:SetToolTip(AGP.L("agp_ui_dak_dial_tip", "The weapon dials every Stargate and sends the wave through them."))

        local NumSliderThingy3 = vgui.Create("DNumSlider", DermaPanel)
        NumSliderThingy3:SetPos(25, 130)
        NumSliderThingy3:SetSize(360, 50)
        NumSliderThingy3:SetText(AGP.L("agp_ui_dak_wave", "Size of the wave"))
        NumSliderThingy3:SetMin(5000)
        NumSliderThingy3:SetMax(18000)
        NumSliderThingy3:SetValue(0)
        NumSliderThingy3:SetDecimals(0)
        NumSliderThingy3:SetToolTip(AGP.L("agp_ui_dakara_power_tip", "The device's power: it sets the radius and the charging time."))


        local MenuButtonClose = vgui.Create("DButton")
        MenuButtonClose:SetParent(DermaPanel)
        MenuButtonClose:SetText(AGP.L("agp_ui_close", "Close"))
        MenuButtonClose:SetPos(25, 230)
        MenuButtonClose:SetSize(75, 25)

        MenuButtonClose.DoClick = function(btn)

            DermaPanel:Remove()
        end

        local MenuButtonCreate = vgui.Create("DButton")
        MenuButtonCreate:SetParent(DermaPanel)
        MenuButtonCreate:SetText(AGP.L("agp_ui_launch", "Launch"))
        MenuButtonCreate:SetPos(125, 230)
        MenuButtonCreate:SetSize(75, 25)

        MenuButtonCreate.DoClick = function(btn)
            local d_ply = 0
            local d_prp = 0
            local d_veh = 0
            local d_rep = 0
            local d_npc = 0
            local d_gate = 0
            local power = NumSliderThingy2:GetValue() + 5
            local range = NumSliderThingy3:GetValue()

            if (CheckBoxThing1:GetChecked()) then
                d_ply = 1
            end

            if (CheckBoxThing2:GetChecked()) then
                d_prp = 1
            end

            if (CheckBoxThing3:GetChecked()) then
                d_veh = 1
            end

            if (CheckBoxThing4:GetChecked()) then
                d_rep = 1
            end

            if (CheckBoxThing5:GetChecked()) then
                d_npc = 1
            end
            
            if (CheckBoxThing8:GetChecked()) then
                d_gate = 1
            end

            LocalPlayer():ConCommand("AP" .. e:EntIndex() .. " " .. power .. " " .. d_ply .. " " .. d_prp .. " " .. d_veh .. " " .. d_rep .. " " .. d_npc.." "..range.." "..d_gate)
            DermaPanel:Remove()
        end
    end

    vgui.Register("AncientEntry", VGUI)

    local function AncientPanel(um) -- fix: was a global function
        local Window = vgui.Create("AncientEntry")
        Window:SetMouseInputEnabled(true)
        Window:SetVisible(true)
        e = um:ReadEntity()
        if (not IsValid(e)) then return end
    end

    usermessage.Hook("AncientPanel", AncientPanel)
end