--[[
	Lucian Door Opener
	Copyright (C) 2015 Gmod4phun
]]
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Lucian Door Opener"
ENT.Author = "Gmod4phun"
ENT.Category = "Misc Devices"
ENT.WireDebugName = "Lucian Door Opener"
ENT.AutomaticFrameAdvance = true
ENT.Untouchable = true

if CLIENT then
    ENT.SpritePositions = {Vector(1.5, 1.5, 0.545), Vector(1.6, 1.4, 0.545), Vector(1.4, 1.6, 0.545), Vector(-1.5, 1.5, 0.545), Vector(-1.6, 1.4, 0.545), Vector(-1.4, 1.6, 0.545), Vector(1.5, -1.5, 0.545), Vector(1.6, -1.4, 0.545), Vector(1.4, -1.6, 0.545), Vector(-1.5, -1.5, 0.545), Vector(-1.6, -1.4, 0.545), Vector(-1.4, -1.6, 0.545)}

    ENT.SpriteColor = Color(255, 0, 0, 255)

    function ENT:Draw()
        self:SetupBones()
        self:SetRenderMode(RENDERMODE_TRANSALPHA)
        self:DrawModel()
        render.SetMaterial(Material("sprites/bluecore"))

        for i = 1, #self.SpritePositions do
            render.DrawSprite(self:LocalToWorld(self.SpritePositions[i]), 0.2, 0.2, self.SpriteColor)
        end
    end

    function ENT:DrawTranslucent()
        self:Draw()
    end

    function ENT:OnRemove()
    end

    net.Receive("CAP_LDO_SpriteColorUpdate", function()
        local tab = net.ReadTable()
        local color = net.ReadColor()

        for _, device in pairs(tab) do
            if device ~= NULL then
                device.SpriteColor = color
            end
        end
    end)
end

if SERVER then
    if (StarGate == nil or StarGate.CheckModule == nil or not StarGate.CheckModule("devices")) then return end
    AddCSLuaFile()
    util.AddNetworkString("CAP_LDO_SpriteColorUpdate")

    function ENT:Initialize()
        self.Entity:SetModel("models/gmod4phun/lucian_door_opener.mdl")
        self.Entity:PhysicsInit(SOLID_VPHYSICS)
        self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
        self.Entity:SetSolid(SOLID_VPHYSICS)
        self:SetUseType(ONOFF_USE)
        self.Entity.Attached = false
        self.Entity.SecondAttached = false
        self.Entity.TargetDoor = nil
        self.Entity.IsMain = nil
        self.CanUse = CurTime()
        self.GetTimer = 0
        self.Activator = NULL
    end

    function ENT:RemoveBothLDO()
        if IsValid(self.Entity) then
            self.Entity:Remove()
        end

        if IsValid(self.Entity) and IsValid(self.Entity.SecondLucianDevice) then
            self.Entity.SecondLucianDevice:Remove()
        end

        if IsValid(self.Entity) and IsValid(self.Entity.MainLDO) then
            self.Entity.MainLDO:Remove()
        end
    end

    function ENT:Use(activator, _, use)
        if self.CanUse > CurTime() then
            if (use == 0) then
                self.GetTimer = 0
                self.Activator = NULL
            end

            return
        end

        if not IsValid(self.TargetDoor) then return end
        self.CanUse = CurTime() + 2.5
        self.GetTimer = CurTime() + 0.75
        self.Activator = activator

        if IsValid(self.Entity) and IsValid(self.Entity.TargetDoor) and not activator:KeyDown(IN_WALK) then
            if self.Entity.TargetDoor.Open ~= true and self.Entity.TargetDoor.CanDoAnim then
                self:EmitSound("npc/scanner/cbot_servoscared.wav", 70, 100)

                timer.Simple(0.7, function()
                    if IsValid(self) and IsValid(self.TargetDoor) then
                        self:EmitSound("npc/scanner/combat_scan4.wav", 70, 100)
                        self:UpdateSpriteColor(Color(0, 255, 0))
                    end
                end)

                timer.Simple(1.2, function()
                    if IsValid(self) and IsValid(self.TargetDoor) then
                        self.TargetDoor:Toggle()
                    end
                end)

                timer.Simple(2.0, function()
                    if IsValid(self) and IsValid(self.TargetDoor) then
                        self:UpdateSpriteColor(Color(255, 0, 0))
                    end
                end)
            end

            if self.Entity.TargetDoor.Open == true and self.Entity.TargetDoor.CanDoAnim then
                self.Entity.TargetDoor:Toggle()
            end
        end
    end

    -- AGP: attach after the touch callback (collision group, bone follow and no-collide inside it can crash)
    function ENT:AGPAttach(door)
        if (not IsValid(self) or not IsValid(door)) then return end
        self.IsMain = true
        self.TargetDoor = door
        self:SetPos(door:LocalToWorld(Vector(0, 0, 0)))
        self:SetAngles(door:LocalToWorldAngles(Angle(90, 0, 0)))
        self:SetCollisionGroup(COLLISION_GROUP_WORLD)
        self:FollowBone(door, door:LookupBone("RightLock"))
        constraint.NoCollide(self, door, 0, 0)
    end

    function ENT:Touch(ent)
        local door
        if ent:GetClass() == "cap_doors" and ent:GetModel() == "models/madman07/doors/dest_door.mdl" and ent.Attached ~= true then
            door = ent
        elseif ent:GetClass() == "cap_doors_frame" and ent:GetModel() == "models/madman07/doors/dest_frame.mdl" and IsValid(ent.Door) and ent.Door.Attached ~= true then
            door = ent.Door
        end
        if (door) then
            door.Attached = true
            self.TargetDoor = door -- known at once (Think needs it), the physics changes come a tick later
            timer.Simple(0, function() if (IsValid(self)) then self:AGPAttach(door) end end)
        end
    end

    function ENT:Think()
        if not IsValid(self.Entity.TargetDoor) then
            self:Remove()

            return
        end

        if (self.GetTimer ~= 0 and CurTime() - self.GetTimer > 0) then
            local activator = self.Activator

            if (IsValid(activator)) then
                activator:Give("lucian_door_opener_wep")
            end

            self:RemoveBothLDO()

            return
        end

        if self.Entity.TargetDoor.Attached and not self.Entity.SecondAttached and not self.Entity.TargetDoor.LucianProcessDone then
            local second = ents.Create("lucian_door_opener")
            second:Spawn()
            second:Activate()
            self.Entity.SecondAttached = true
            second.MainLDO = self.Entity
            second.IsMain = false
            second.TargetDoor = self.Entity.TargetDoor
            second:SetPos(self.Entity.TargetDoor:LocalToWorld(Vector(0, 0, 0)))
            second:SetAngles(self.Entity.TargetDoor:LocalToWorldAngles(Angle(90, 0, 0)))
            second:SetCollisionGroup(COLLISION_GROUP_WORLD)
            second:FollowBone(self.Entity.TargetDoor, self.Entity.TargetDoor:LookupBone("LeftLock"))
            second.Owner = second.MainLDO.Owner
            constraint.NoCollide(second, self.Entity.TargetDoor, 0, 0)
            self.Entity.SecondLucianDevice = second
            self.Entity.SecondLucianDevice.Untouchable = true
            self.Entity.TargetDoor.LucianProcessDone = true
        end

        self.Entity:NextThink(CurTime())
    end

    function ENT:OnRemove()
        self.Entity.Attached = false
        self.Entity.SecondAttached = false

        if IsValid(self.Entity.TargetDoor) then
            self.Entity.TargetDoor.Attached = false
            self.Entity.TargetDoor.LucianProcessDone = false
        end

        if IsValid(self.Entity.SecondLucianDevice) then
            self.Entity.SecondLucianDevice:Remove()
            self.Entity:Remove()
        end

        if IsValid(self.Entity) and IsValid(self.Entity.SecondLucianDevice) then
            self.Entity.SecondLucianDevice:Remove()
        end

        if IsValid(self.Entity) and IsValid(self.Entity.TargetDoor) and self.Entity.TargetDoor.Open == true then
            self.Entity.TargetDoor:Toggle()
        end
    end

    function ENT:PostEntityPaste()
        self:Remove()
    end
end

-- returns the 2 LDO entities
function ENT:GetPair()
    if IsValid(self) and IsValid(self.SecondLucianDevice) then
        return {self, self.SecondLucianDevice}
    elseif IsValid(self) and IsValid(self.MainLDO) then
        return {self, self.MainLDO}
    else
        -- in case one of them wasnt found
        return NULL, NULL
    end
end

-- convenient function to change the color (server and client) if needed
function ENT:UpdateSpriteColor(color)
    local e = self
    local tab = e:GetPair()

    if CLIENT then
        for k, device in pairs(tab) do
            if IsValid(device) then
                device.SpriteColor = color
            end
        end
    else
        net.Start("CAP_LDO_SpriteColorUpdate")
        net.WriteTable(tab)
        net.WriteColor(color)
        net.Broadcast()
    end
end