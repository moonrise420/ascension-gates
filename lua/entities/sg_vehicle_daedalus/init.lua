--[[
	BC-304 "Daedalus"
	Copyright (C) 2010 Madman07

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.

]]
--
if (StarGate == nil or StarGate.CheckModule == nil or not StarGate.CheckModule("ship")) then return end
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

-- AGP: shield on G, see lua/autorun/agp_ship_shield.lua. The biggest bubble in the pack (4000x4000x3500) is shorter
-- than the hull (5800 long): bow and stern stick out of the bubble, but the shot box (bounds) covers the whole ship.
-- the hull (~5800 long) is longer than the biggest bubble: stretched 1.85x along the ship so bow and stern are inside
ENT.AGPShield = { model = "models/iziraider/shields/8x8x7.mdl", yaw = 0, offset = Vector(90, 8, 53), bounds = Vector(3800, 3200, 950), color = { 0.6, 0.8, 1 }, scale = Vector(1.872, 1.579, 0.513) }
-- (balance, the series' order: Ori > O'Neill > Aurora > Daedalus > Destiny > Prometheus > Al'kesh > Tel'tak) the shield
-- holds 28000 damage (a beam: 28 s)
ENT.AGPShieldHP, ENT.AGPShieldBeamTime = 28000, 28

-- AGP: hyperdrive on H (hold to charge, release to jump), lua/autorun/agp_ship_hyperdrive.lua
ENT.AGPHyperRange = 30000

-----------------------------------INIT----------------------------------
function ENT:Initialize()
    self.Vehicle = "Daedalus"
    self.Entity:SetModel("models/Madman07/daedalus/daedalus.mdl")
    self.Entity:SetName("BC-304 Daedalus")
    self.Entity:PhysicsInit(SOLID_VPHYSICS)
    self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
    self.Entity:SetSolid(SOLID_VPHYSICS)
    self.Entity:StartMotionController()
    local phys = self.Entity:GetPhysicsObject()
    self:SetNWInt("clmaxhealth", self.MaxHealth)

    if IsValid(phys) then
        phys:Wake()
        phys:SetMass(50000)
    end

    self.Railgun = {}
    self.MissileMaxVel = 10000000
    self.TrackTime = 1000000
    self.Fired = false
    self.Rocket = {}
    self.RocketTarget = nil

    self.FlightPhys = {
        secondstoarrive = 1,
        maxangular = 10000000,
        maxangulardamp = 100000,
        maxspeed = 10000000,
        maxspeeddamp = 500000,
        dampfactor = 1,
        teleportdistance = 5000
    }

    self.Forw = 0
    self.Angles = Angle(0, 0, 0)
    self.LastYaw = self.Entity:GetAngles().Yaw
    self.KeyRoll = 0
    self.HoverPos = self.Entity:GetPos()
    self.lastpos = nil
    self.GoUp = 0
    self.Active = false
    self.Pressed = false
    self.Driver = NULL
    self.weps = {}
    self.TargetMode = 0
    self:SetNWInt("ViewMode", 0)
    self.Target = self:GetPos()
    self.RailgunTracing = false
    self.RailgunShoot = false
    self:CreateWireInputs("Hyperspace [VECTOR]") -- AGP: Wire jump target for the hyperdrive (H)
    self:CreateWireOutputs("Health")
    self.EntHealth = 28000   -- (balance: a plain hull, every hit counts in full)
    self.MaxHealth = self.EntHealth
    self:SetWire("Health", self.EntHealth)
    -- AGP: networked hull for the HUD ("clmaxhealth" was set before MaxHealth existed, "Hull" never)
    self:SetNWInt("clmaxhealth", self.MaxHealth); self:SetNWInt("maxEntHealth", self.MaxHealth)
    self:SetNWInt("health", self.EntHealth); self:SetNWInt("Hull", 100)

    timer.Create("SGDaedalusHealthRegen" .. self:EntIndex(), 2, 0, function()
        if (not IsValid(self)) then return end
        self.EntHealth = math.Clamp(self.EntHealth + 50, 0, self.MaxHealth)
        self:AGPUpdateSystems()
        self:SetWire("Health", self.EntHealth)
        self:SetNWInt("health", math.ceil(self.EntHealth)); self:SetNWInt("Hull", math.ceil(self.EntHealth / self.MaxHealth * 100)) -- AGP
    end)
end

-----------------------------------SPAWN----------------------------------
function ENT:SpawnFunction(ply, tr)
    -- if(ply:GetCount("ships_daedalus")+1 > PropLimit) then
    local PropLimit = GetConVar("CAP_ships_max"):GetInt()

    if (ply:GetCount("CAP_ships") + 1 > PropLimit) then
        ply:SendLua("GAMEMODE:AddNotify(SGLanguage.GetMessage(\"entity_limit_ships\"), NOTIFY_ERROR, 5); surface.PlaySound(\"buttons/button2.wav\")") -- fix: message text was unquoted (client Lua error)

        return
    end

    ent = ents.Create("sg_vehicle_daedalus")
    ent:SetPos(tr.HitPos + Vector(0, 0, 800))
    ent:Spawn()
    ent:Activate()
    -- AGP: on the ground where the player aims (it was 800 units over the player's head and hovered there; new ships
    -- now settle on the ground until they are flown, so it would have dropped onto the player)
    ent:SetPos(tr.HitPos + Vector(0, 0, 20 - ent:OBBMins().z))
    ent.Owner = ply
    ent:SpawnRailguns(ply)
    ent:SpawnRotor(ply)
    ply:AddCount("CAP_ships", ent)
    return ent
end

-----------------------------------POWER----------------------------------
-----------------------------------SPAWN ROTORWASH----------------------------------
function ENT:SpawnRotor(p)
    local ent = NULL

    local SpawnPos = {self:LocalToWorld(Vector(2500, 0, -450)), self:LocalToWorld(Vector(2000, 0, -450)), self:LocalToWorld(Vector(-500, 1250, -450)), self:LocalToWorld(Vector(-1000, 1250, -450)), self:LocalToWorld(Vector(-1500, 1250, -450)), self:LocalToWorld(Vector(-500, -1250, -450)), self:LocalToWorld(Vector(-1000, -1250, -450)), self:LocalToWorld(Vector(-1500, -1250, -450))}

    for i = 1, 8 do
        ent = ents.Create("env_rotorwash_emitter")
        ent:SetPos(SpawnPos[i])
        ent:Spawn()
        ent:Activate()
        ent:SetOwner(self.Entity)
        ent:SetParent(self.Entity)
        ent:SetKeyValue("Altitude", "1000")

        if CPPI and IsValid(p) and ent.CPPISetOwner then
            ent:CPPISetOwner(p)
        end
    end
end

----self.flashlight:Input( "SpotlightTexture", NULL, NULL, self:GetFlashlightTexture() )
-----------------------------------SPAWN RAILGUNS----------------------------------
function ENT:SpawnRailguns(p)
    local att = {"TLF", "TLM", "TLT", "TLB", "TRF", "TRM", "TRT", "TRB"}

    local ent = NULL
    local ang = self:GetAngles()

    for i = 1, 8 do
        local data = self:GetAttachment(self:LookupAttachment(att[i]))
        if not (data and data.Pos) then return end
        ent = ents.Create("sg_turret_daedalus")
        if (IsValid(ent)) then ent.DoNotDuplicate = true end   -- (built by its parent, which builds it again after a save or a paste - copied as well it was there twice)
        ent:SetModel("models/Madman07/daedalus/turret.mdl")
        ent:SetPos(data.Pos)
        ent:SetAngles(ang)
        ent.Parent = self
        -- AGP balance: 8 turrets x 2 muzzles x 10 shots a second did 1400 a second on their own (more than the
        -- Ori's beam); a third of that, with the Asgard beam and the missiles ~1100 like the plan
        ent.AGPDamageScale = 0.3
        ent:Spawn()
        ent:Activate()
        ent:SetOwner(self.Entity)
        ent:SetParent(self.Entity)

        if CPPI and IsValid(p) and ent.CPPISetOwner then
            ent:CPPISetOwner(p)
        end

        local phys = ent:GetPhysicsObject()

        if IsValid(phys) then
            phys:Wake()
        end

        table.insert(self.Railgun, ent)
    end
end

-----------------------------------SPAWN ASGARD----------------------------------
-----------------------------------SPAWN TRANSPORTER----------------------------------
-----------------------------------SPAWN RINGS----------------------------------
--
-----------------------------------FIRE RAILGUN----------------------------------
function ENT:AimRailgun(target)
    for _, v in pairs(self.Railgun) do
        if IsValid(v) then
            v:Aim(target)
        end
    end
end

-- AGP: damaged systems really go offline (the flags were set, but nothing read them): under 4000 hull the rail guns
-- and missiles, under 2000 the Asgard beam. They come back when the hull is repaired or regenerates.
local SYSTEMS = {
    { flag = "RailgunEnable", below = 4000, key = "agp_msg_dd_rails", name = "Rail guns" },
    { flag = "RocketEnable", below = 4000, key = "agp_msg_dd_rockets", name = "Missiles" },
    { flag = "AsgardBeamEnable", below = 2000, key = "agp_msg_dd_beam", name = "Asgard beam" },
}
function ENT:AGPUpdateSystems()
    for _, sys in ipairs(SYSTEMS) do
        local on = (self.EntHealth or 0) >= sys.below
        if (self[sys.flag] ~= on) then
            local was = self[sys.flag]
            self[sys.flag] = on
            self:SetNWBool("AGP" .. sys.flag, on)
            if (was ~= nil and IsValid(self.Driver)) then
                if (on) then AGP.Say(self.Driver, sys.key .. "_on", sys.name .. " back online")
                else AGP.Say(self.Driver, sys.key .. "_off", sys.name .. " offline - hull too damaged"); self:EmitSound("buttons/button8.wav", 90, 80) end
            end
        end
    end
end

function ENT:FireRailgun(target)
    if (self.RailgunEnable == false) then return end
    for _, v in pairs(self.Railgun) do
        if IsValid(v) then
            v:DoShoot()
        end
    end
end

-----------------------------------FIRE ASGARD----------------------------------
function ENT:FireAsgard(target)
    if (self.AsgardBeamEnable == false) then return end
    local att = {"ALB", "ALF", "ALT", "ARB", "ARF", "ART"}

    -- AGP: from the first emitter (in random order) that sees the target; one random emitter was often behind the
    -- hull or a rail gun turret, and then no beam came at all (balance test: no beam in 12 s)
    local first, data, tr = math.random(1, 6)
    for k = 0, 5 do
        data = self:GetAttachment(self:LookupAttachment(att[(first + k - 1) % 6 + 1]))
        if (data and data.Pos) then
            tr = util.TraceLine({ start = data.Pos + data.Ang:Forward() * 50, endpos = target })
            if not (IsValid(tr.Entity) and (tr.Entity == self.Entity or tr.Entity:GetParent() == self.Entity)) then break end
        end
        tr = nil
    end

    if (tr) then
        local ShootDir = (target - data.Pos):GetNormal()
        local ent = ents.Create("energy_beam2")
        ent.Owner = self.Entity
        ent:SetPos(data.Pos)
        ent:Spawn()
        ent:Activate()
        ent:SetOwner(self.Entity)
        ent:Setup(data.Pos, ShootDir, 1200, 1.5, "Asgard")
    end
end

-----------------------------------FIRE ROCKET----------------------------------
function ENT:FireRocket(num)
    if (self.RocketEnable == false) then return end
    local Ratt = {"RR1", "RR2", "RR3", "RR4", "RR5", "RR6", "RR7", "RR8"}

    local Latt = {"RL1", "RL2", "RL3", "RL4", "RL5", "RL6", "RL7", "RL8"}

    local ent = NULL
    local data = self:GetAttachment(self:LookupAttachment(Ratt[num]))
    if not (data and data.Pos and data.Ang) then return end
    ent = ents.Create("302missile")
    ent.Parent = self
    ent:SetPos(data.Pos - self:GetUp() * 50)
    ent:SetAngles(data.Ang)
    ent:Spawn()
    ent:Activate()
    ent:SetVelocity(Vector(0, 0, 1) * self.MissileMaxVel)
    ent:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)
    ent:SetOwner(self.Entity)
    ent.AGPSweep = true -- AGP: it hits whatever lies on its path (fast, it flew through hulls)
    local data = self:GetAttachment(self:LookupAttachment(Latt[num]))
    if not (data and data.Pos and data.Ang) then return end
    ent = ents.Create("302missile")
    ent.Parent = self
    ent:SetPos(data.Pos - self:GetUp() * 50)
    ent:SetAngles(data.Ang)
    ent:Spawn()
    ent:Activate()
    ent:SetVelocity(Vector(0, 0, 1) * self.MissileMaxVel)
    ent:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)
    ent:SetOwner(self.Entity)
    ent.AGPSweep = true -- AGP: it hits whatever lies on its path (fast, it flew through hulls)
end

-----------------------------------THINK----------------------------------
function ENT:Think(ply)
    if (AGP.ShipHyperdriveThink) then AGP.ShipHyperdriveThink(self) end -- AGP: hyperdrive (H)
    -- AGP: the missiles (302missile, base "drone") fly to Target while Track is set; nothing set them, so they only flew
    -- straight up out of the launch tubes. Now they climb out and then go where the pilot aims.
    if (self.Active and IsValid(self.Driver)) then
        -- from the camera of the current view along the view: the aim point is the screen centre
        local aim = self.Driver:GetAimVector()
        local start = self:GetPos() + self:GetUp() * 600 - aim * 5000
        if (self.TargetMode == 1) then start = self:GetPos() - self:GetUp() * 500 elseif (self.TargetMode == 2) then start = self:GetPos() + self:GetUp() * 1000 end
        local tr = util.TraceLine({ start = start, endpos = start + aim * 60000,
            filter = function(e) return e ~= self and e ~= self.Driver and e:GetClass() ~= "302missile" and not (AGP.ShipPart and AGP.ShipPart(self, e)) end })
        -- AGP: the point the pilot's own camera sees under the crosshair when the client sent one (exact in every view,
        -- lua/autorun/agp_ship_aim.lua); the line above rebuilds the camera only roughly
        tr.HitPos = AGP.ShipClientAim and AGP.ShipClientAim(self.Driver, self) or tr.HitPos
        self.Target = tr.HitPos
        self.Track = true
        self:SetNWVector("AGPAim", tr.HitPos)
    else
        self.Track = false
    end
    if (self.Active and IsValid(self.Driver)) then
        for i = 1, 8 do
            if (self.Driver:KeyDown(self.Vehicle, tostring(i)) and CurTime() >= (self.AGPNextRocket or 0)) then
                self.AGPNextRocket = CurTime() + 0.8 -- AGP balance: one pair of missiles per 0.8 s (was every 0.1 s)
                self:FireRocket(i)
                break
            end
        end
        
        self:SetNWInt("Power",100);
        -- AGP: hull plate follows every hit (it was only refreshed by the 2 s repair timer)
        self:SetNWInt("Hull", math.Clamp(math.ceil((self.EntHealth or 0) / math.max(1, self.MaxHealth or 1) * 100), 0, 100));
        self:SetNWInt("Hangar",0);
        self:SetNWInt("PowerSource",self.ZPMPlugged);
        -- AGP: the HUD shield lamp and bar now show the real shield (ShieldsEnable was never set)
        if (AGP.ShipShieldThink) then AGP.ShipShieldThink(self) end
        self:SetNWInt("ShieldStatus", self:GetNWBool("AGPShieldOn", false) and 1 or 0);
        self:SetNWInt("Shield", self:GetNWInt("AGPShieldStrength", 100));
        self:SetNWInt("Hyperdrive", self:GetNWInt("AGPHyperCharge", 0)); -- AGP: the real charge (was always 0)
        if (self.Driver:KeyDown(self.Vehicle, "EXIT")) then
            self.Entity:Exit()

            return
        end

        if (AGP.KeyPress(self, self.Driver, self.Vehicle, "MODE") and self.Pressed == false) then
            if (self.TargetMode == 0) then
                self.TargetMode = 1
            elseif (self.TargetMode == 1) then
                self.TargetMode = 2
            else
                self.TargetMode = 0
            end

            self.Pressed = true
            self.AGPPressedUntil = CurTime() + 1
            self:SetNWInt("ViewMode", self.TargetMode)
        end

        -- the view of the mode: 1 under the hull, 2 above it, 0 the flight view
        if (self.TargetMode == 1) then
            self.Driver:SetPos(self.Entity:GetPos() - self.Entity:GetUp() * 500)
        elseif (self.TargetMode == 2) then
            self.Driver:SetPos(self.Entity:GetPos() + self.Entity:GetUp() * 1000)
        else
            self.Driver:SetPos(self.Entity:GetPos())
        end

        -- AGP: rail guns (FIRE) and Asgard beam (FIRE2) in every mode, aimed at the crosshair (self.Target, set above).
        -- They fired only in the two gun views, and aimed at AimVector*10^14 (a point from the map centre).
        if self.Driver:KeyDown(self.Vehicle, "FIRE2") and CurTime() >= (self.AGPNextBeam or 0) then
            self.AGPNextBeam = CurTime() + 3 -- AGP balance: one Asgard beam per 3 s, like the O'Neill (was one per 0.1 s)
            self:FireAsgard(self.Target)
        end

        if (self.Driver:KeyDown(self.Vehicle, "FIRE")) then
            self:FireRailgun()
        end

        self:AimRailgun(self.Target)

        if (self.Pressed == true and CurTime() > (self.AGPPressedUntil or 0)) then -- AGP: was a new 1 s timer every Think
            self.Pressed = false
        end
    end

    self.Entity:NextThink(CurTime() + 0.1)

    return true
end

-----------------------------------PHYSIC----------------------------------
function ENT:PhysicsSimulate(phys, deltatime)
    if (self.Active and IsValid(self.Driver) and (self.TargetMode == 0)) then
        local FWD = self.Entity:GetForward()
        local speed = 0
        local up = 0
        local acc = 10

        if (self.Driver:KeyDown(self.Vehicle, "FWD")) then
            speed = 2000
        elseif (self.Driver:KeyDown(self.Vehicle, "BACK")) then
            speed = -500
        end

        if (self.Driver:KeyDown(self.Vehicle, "SPD")) then
            speed = 3000
            acc = 40
        end

        self.Forw = math.Approach(self.Forw, speed, acc)

        if (self.Driver:KeyDown(self.Vehicle, "UP")) then
            up = 300
        elseif (self.Driver:KeyDown(self.Vehicle, "DOWN")) then
            up = -300
        end

        self.GoUp = math.Approach(self.GoUp, up, 10)

        if (self.Driver:KeyDown(self.Vehicle, "FWD") or self.Driver:KeyDown(self.Vehicle, "BACK") or self.Driver:KeyDown(self.Vehicle, "SPD")) then
            local aim = AGP.SteerAim(self, self.Driver) -- AGP: ALT = free look
            local ang = aim:Angle()
            self.Angles.Pitch = math.ApproachAngle(self.Angles.Pitch, ang.Pitch, 0.5)
            self.Angles.Yaw = math.ApproachAngle(self.Angles.Yaw, ang.Yaw, 0.5)
        elseif (self.Driver:KeyDown(self.Vehicle, "LEFT")) then
            self.Angles.Yaw = self.Angles.Yaw + 0.5
        elseif (self.Driver:KeyDown(self.Vehicle, "RIGHT")) then
            self.Angles.Yaw = self.Angles.Yaw - 0.5
        end

        local velocity = self:GetVelocity()

        if (up ~= 0) then
            velocity.z = 0
        end

        local Sublight = math.Round(velocity:Length()/19.3);
        if (self.Forw < -5) then
            self:SetNWInt("Sublight",-10);
        else 
            self:SetNWInt("Sublight",Sublight); 
        end

        local AerodynamicRoll = self.Entity:GetAngles().Yaw - self.LastYaw
        local max = math.Clamp((velocity:Length() / 40), 0, 60)
        local oldRoll = self.Angles.Roll
        self.Angles.Roll = -1 * AerodynamicRoll * max + self.KeyRoll

        -- fix for nan values what cause despawing/crash.
        if (self.Angles.Roll ~= self.Angles.Roll) then
            self.Angles.Roll = oldRoll
        end

        self.LastYaw = self.Entity:GetAngles().Yaw
        self.HoverPos = self.Entity:GetPos()
        self.FlightPhys.pos = self:GetPos() + (FWD * self.Forw) + Vector(0, 0, self.GoUp)
    else
        if (not self.AGPFlown) then return end -- AGP: a new Daedalus settles on the ground until someone has flown it
        self.FlightPhys.pos = self.HoverPos
    end

    self.FlightPhys.angle = self.Angles
    self.FlightPhys.deltatime = deltatime
    phys:Wake()
    phys:ComputeShadowControl(self.FlightPhys)
end

-----------------------------------OTHER----------------------------------
function ENT:OnRemove()
    if (self.Active) then
        self.Entity:Exit()
    end
    timer.Remove("SGDaedalusHealthRegen" .. self:EntIndex())
    if (AGP.ShipShieldRemove) then AGP.ShipShieldRemove(self) end -- AGP
    self:Remove()
end

-- AGP: the shared ship damage (lua/autorun/agp_ship_shield.lua AGP.ShipHullDamage): shield first, then the hull; beam
-- hits (Asuran gate weapon) count without a minimum, at half (the hull: ~90 s of the beam); other hits a fifth as before.
-- Before, the beam never reached the hull and the destruction test subtracted the damage a second time.
ENT.AGPHullShip = true          -- a ship for the gate weapon and the crew protection (not derived from sg_vehicle_base)
ENT.AGPHullInEntHealth = true
function ENT:OnTakeDamage(dmg)
    if (not AGP.ShipHullDamage) then return end
    if (AGP.ShipHullDamage(self, dmg) <= 0 or self.AGPDestroyed) then return end
    self:AGPUpdateSystems()
end

function ENT:AGPHullDestroyed()
    self:Detonate() --2 of them to make the explosion more severe
    self:Detonate()
end

-- AGP: Wire input "Hyperspace" [VECTOR] = the hyperdrive's jump target (it was declared, but nothing read it:
-- base_anim has no TriggerInput)
function ENT:TriggerInput(k, v)
    if (AGP and AGP.ShipHyperdriveInput) then AGP.ShipHyperdriveInput(self, k, v) end
end

function ENT:HealthRepair(health)
    self.EntHealth = health
    self:AGPUpdateSystems() -- AGP: back online above the limits (the old else-chain could never restore rails/missiles)
end

 function ENT:Detonate()
    local nuke = ents.Create("gate_nuke")
	nuke:Setup(self.Entity:GetPos(), 100)
	nuke:Spawn()
	nuke:Activate()

    if (self.Active) then
        self.Entity:Exit();
    end
    self.Entity:Remove()
 end
-----------------------------------USE/ENTER----------------------------------
function ENT:Use(ply, caller)
    self.Entity:SetUseType(SIMPLE_USE)

    if (not self.Active or not IsValid(self.Driver)) then -- AGP: a pilot who left the game does not block it
        self.Active = true
        self.Driver = ply
        self.Angles = self:GetAngles() -- AGP: fly on from where it points (it swung round to world angle 0)
        self.weps = {}
        self.AGPFlown = true -- AGP: from now on it hovers when left
        self.Driver:SetPos(self.Entity:GetPos())
        self.Driver:SetNetworkedEntity("ScriptedVehicle", self)
        self.Driver:SetViewEntity(self)
        -- Garry broke this function
        self.Driver:SetMoveType(MOVETYPE_OBSERVER)
        self.Driver:DrawViewModel(false)
        self.Driver:DrawWorldModel(false)
        self.Driver:Spectate(OBS_MODE_CHASE)

        for k, v in pairs(self.Driver:GetWeapons()) do
            table.insert(self.weps, v:GetClass())
        end

        self.Driver:StripWeapons()
        self.Driver:SetNetworkedEntity("Daedalus", self)
    end

    self.Entity:NextThink(CurTime() + 0.5)
end

-----------------------------------EXIT----------------------------------
function ENT:Exit()
    self.Active = false
    if (not IsValid(self.Driver)) then return end
    StarGate.KeyBoard.ResetKeys(self.Driver, self.Vehicle)
    self.Driver:UnSpectate()
    self.Driver:DrawViewModel(true)
    self.Driver:DrawWorldModel(true)
    -- AGP: on the ground under the ship, or next to it when it is landed (it was 400 units under the centre: inside the
    -- hull or the ground, and the game threw the player into the air)
    self.Driver:SetPos(AGP.ShipExitSpot(self, self.Driver, nil))
    self.Driver:SetVelocity(-self.Driver:GetVelocity())
    self.Driver:SetMoveType(MOVETYPE_WALK);
    self.Driver:SetCollisionGroup(COLLISION_GROUP_PLAYER);

    for k, v in pairs(self.weps) do
        self.Driver:Give(tostring(v))
    end
    self.weps = {} -- AGP: the next pilot gets only his own weapons back

    self.Driver:SetParent()
    self.Driver:SetNetworkedEntity("ScriptedVehicle", NULL)
    self.Driver:SetViewEntity(NULL)
    -- Garry broke this function
    self.Driver:SetNetworkedEntity("Daedalus", NULL)
    self.Driver = NULL
end

---shut.AsgardBeamEnable = !shut.AsgardBeamEnable;
function ENT:PostEntityPaste(ply, Ent, CreatedEntities)
    if (StarGate.NotSpawnable(Ent:GetClass(), ply)) then
        self.Entity:Remove()

        return
    end

    if (IsValid(ply)) then
        local PropLimit = GetConVar("CAP_ships_max"):GetInt()

        if (ply:GetCount("CAP_ships") + 1 > PropLimit) then
            ply:SendLua("GAMEMODE:AddNotify(SGLanguage.GetMessage(\"entity_limit_ships\"), NOTIFY_ERROR, 5); surface.PlaySound(\"buttons/button2.wav\")") -- fix: message text was unquoted (client Lua error)
            Ent:Remove()

            return
        end

        ply:AddCount("CAP_ships", Ent)
    end

    self:SpawnRailguns(ply)
    self:SpawnRotor(ply)
    StarGate.WireRD.PostEntityPaste(self, ply, Ent, CreatedEntities)
end

if (StarGate and StarGate.CAP_GmodDuplicator) then
    duplicator.RegisterEntityClass("sg_vehicle_daedalus", StarGate.CAP_GmodDuplicator, "Data")
end

--################# After teleporting it, fix the angles of a player @aVoN
function ENT.FixAngles(self, pos, ang, vel, old_pos, old_ang, old_vel, ang_delta)
    -- Move a players view
    local diff = Angle(0, ang_delta.y + 180, 0)

    if (IsValid(self.Driver)) then
        self.Driver:SetEyeAngles(self.Driver:GetAimVector():Angle() + diff)
    end
end

StarGate.Teleport:Add("sg_vehicle_daedalus", ENT.FixAngles)
