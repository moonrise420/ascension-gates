/*
	KINO Remote for Garry's Mod 11
	Scripted by Sutich and Madman07; Sources from aVoN's Stargate Mod
	Kino Remote Model by Iziraider
	Textures by Rafael De Jongh
	Copyright (C) 2010

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
*/

if (StarGate==nil or StarGate.CheckModule==nil or not StarGate.CheckModule("extra")) then return end
if (SGLanguage!=nil and SGLanguage.GetMessage!=nil) then
SWEP.PrintName = SGLanguage.GetMessage("weapon_misc_kino");
SWEP.Category = SGLanguage.GetMessage("weapon_misc_cat");
end
SWEP.Author = "Suitch, Rafael De Jongh, Iziraider";
SWEP.Contact = "";
SWEP.Purpose = "";
SWEP.Instructions = (AGP and AGP.L) and AGP.L("agp_wp_kinoremote_i", "Left click: use the current mode\nRight click: change the mode") or "Left click: use the current mode\nRight click: change the mode"
SWEP.Base = "weapon_base";
SWEP.Slot = 3;
SWEP.SlotPos = 3;
SWEP.DrawAmmo	= false;
SWEP.DrawCrosshair = true;
SWEP.ViewModel = "models/Iziraider/kinoremote/v_kinoremote.mdl";
SWEP.WorldModel = "models/Iziraider/kinoremote/w_kinoremote.mdl";
SWEP.ViewModelFOV = 90
SWEP.HoldType = "slam"

-- primary.
SWEP.Primary.ClipSize = -1;
SWEP.Primary.DefaultClip = -1;
SWEP.Primary.Automatic = true;
SWEP.Primary.Ammo	= "none";

-- secondary
SWEP.Secondary.ClipSize = -1;
SWEP.Secondary.DefaultClip = -1;
SWEP.Secondary.Automatic = false;
SWEP.Secondary.Ammo	= "none";

-- spawnables.
list.Set("CAP.Weapon", SWEP.PrintName or "", SWEP);

--################### Dummys for the client @ aVoN
function SWEP:PrimaryAttack() return false end
function SWEP:SecondaryAttack() return false end

-- to cancel out default reload function
function SWEP:Reload() return end

function SWEP:Initialize()
	self:SetWeaponHoldType(self.HoldType)
end

if SERVER then
    if (StarGate==nil or StarGate.CheckModule==nil or not StarGate.CheckModule("extra")) then return end

    AddCSLuaFile();

    SWEP.Sounds = {
        TurnOn = Sound("kino/kino_turn_on.wav"),
        Zoom = Sound("kino/kinozoom.wav"),
        SwitchMode1 = Sound("kino/kino_mode1.wav"),
        SwitchMode2 = Sound("kino/kino_mode2.wav"),
    }

    SWEP.AttackMode = 1;
    SWEP.Delay = 5;

    --################### Init the SWEP
    function SWEP:Initialize()
        self:SetWeaponHoldType(self.HoldType);
        self.Range = StarGate.CFG:Get("mobile_dhd","range",3000);

        self.KinoActive = false;
        self.StartPos = self:GetPos();
        self.KinoNumber = 1;
        self.KinoEnt = {}
        self.CanZoom = true;
        self.FOV = 75;
    end

    --################### Initialize
    function SWEP:PrimaryAttack(fast)
        local delay = 0;
        self.Weapon:SetNextPrimaryFire(CurTime()+0.5);
        local e = self.Weapon;
        timer.Simple(delay,
            function()
                if(IsValid(e) and IsValid(e.Owner)) then
                    e:DoShoot();
                    self:EmitSound(self.Sounds.SwitchMode1, 150);
                end
            end
        );
        return true;
    end

    --################### Secondary Attack @ aVoN
    function SWEP:SecondaryAttack()

        if (self.KinoActive == false) then --Change our Mode only if not flying with kino
            self:EmitSound(self.Sounds.SwitchMode2, 150);
            local modes = 3;
            self.AttackMode = math.Clamp((self.AttackMode+1) % (modes + 1),1,modes);
            self.Weapon:SetNWInt("Mode",self.AttackMode); -- Tell client, what mode we are in -- fix: was SetNWBool, but the HUD reads GetNWInt (always showed mode 1)
            self.Owner._KinoRemoteMode = self.AttackMode; -- So modes are saved accross "session" (if he died it's the last mode he used it before)
        else -- if we using kino, switch control to other kino
            self.KinoNumber = self.KinoNumber + 1;

            local number = self:FindKino();
            if (self.KinoNumber > number) then self.KinoNumber = 1; end
            local e = self.KinoEnt[self.KinoNumber];
            if IsValid(e) then
                self.KinoEntActive.IsControlled = false;
                self.KinoEntActive.Remote = nil;
                self.KinoEntActive.Player = nil;
                self.KinoEntActive = e;
                self.KinoEntActive.Remote = self;
                self.KinoEntActive.Player = self.Owner;
                self.KinoEntActive.IsControlled = true;
                self.KinoEntActive:SwitchedKino(self.Owner);
                self.Owner:SetViewEntity(self.KinoEntActive)
                self.Owner:SetNWEntity("Kino", self.KinoEntActive);
            end

        end
    end

    --################### Reset Mode @ aVoN
    function SWEP:OwnerChanged()
        self.AttackMode = self.Owner._KinoRemoteMode or 1;
        self.Weapon:SetNWInt("Mode",self.AttackMode); -- fix: was SetNWBool (HUD reads GetNWInt)
    end

    --################### Do the shot
    function SWEP:DoShoot()
        local p = self.Owner;
        if(not IsValid(p)) then return end;
        local pos = p:GetShootPos();
        if(self.AttackMode == 1) then
            if (self.KinoActive == false) then self:EnterKinoMode();
            else
                self.KinoActive = false;
                self:ExitKino();
            end
        elseif(self.AttackMode == 2) then
            self:OpenMenu(p);
        elseif(self.AttackMode == 3) then
            local ring = self:FindClosestRings();
            if(IsValid(ring) and not ring.Busy) then
                self.Owner.RingDialEnt = ring;
                umsg.Start("RingTransporterShowWindowCap",self.Owner);
                umsg.End();
            end
        end
    end

    function SWEP:Think()

        local nextthink = CurTime()+0.2;

        if (self.KinoActive == true) then
            if IsValid(self.KinoEntActive) then

                self.KinoEntActive:MoveKino();
                self.KinoEntActive:Keys();

                if (self.Owner:GetMoveType() == MOVETYPE_NOCLIP) then
                    self.KinoEntActive:PrepareRemove();
                    self:ExitKino(self.Owner);
                    self.KinoActive = false;
                end

            else
                self.KinoActive = false
                self:ExitKino();
            end

        end

        self:NextThink(nextthink);
        return true
    end

    function SWEP:UpdateTransmitState() return TRANSMIT_ALWAYS; end

    function SWEP:FindKino()
        local number = 0;
        self.KinoEnt = nil
        self.KinoEnt = {}
        for _,v in pairs(ents.FindByClass("kino_ball*")) do
            if (v.Owner == self.Owner) then
                table.insert(self.KinoEnt, v)
                number = number + 1;
            end
        end
        return number
    end

    function SWEP:EnterKinoMode()

        local number = self:FindKino();
        if(number == 0) then return end;

        self.FOV = self.Owner:GetFOV()

        if (self.KinoNumber > number) then self.KinoNumber = 1; end
        self.KinoEntActive = self.KinoEnt[self.KinoNumber]

        self.KinoActive = true;
        self:EnterKino();
    end

    function SWEP:EnterKino()
        self.FOV = self.Owner:GetFOV()
        self.StartPos = self.Owner:GetPos();
        self:EmitSound(self.Sounds.TurnOn, 150);
        self.OriginalAngles = self.Owner:EyeAngles();
        self.Owner.CAP_KINO_FOV = self.FOV;
        self.Owner.CAP_KINO_StartPos = self.StartPos;
        self.Owner:SetObserverMode( OBS_MODE_FIXED )
        self.Owner:SetMoveType(MOVETYPE_NONE);
        self.Owner:SetEyeAngles(self.KinoEntActive:GetAngles());
        self.Owner:SetViewEntity(self.KinoEntActive)
        self.Owner:SetNWEntity("Kino", self.KinoEntActive);
        self.KinoEntActive:SwitchedKino(self.Owner);
        self.KinoEntActive.IsControlled = true;
        self.KinoEntActive.Remote = self;
        self.KinoEntActive.Player = self.Owner;
        self.Owner:SetNWBool("KActive", true);
    end

    -- AGP: out of the KINO view without a respawn's losses (Spawn() ran the loadout: all ammo wiped, health and armour
    -- reset, a Ha'tak bunk moved him away). AGP.ShipRespawnPilot (autorun/agp_ship_shield.lua) keeps armour and ammo,
    -- like kino_ball.lua does; here health, the weapons he carried (with their clips) and nothing more than that (the
    -- loadout's extra weapons and ammo go again).
    local function AGPLeaveKinoView(ply)
        if (not (AGP and AGP.ShipRespawnPilot)) then
            ply:Spawn()
            return
        end

        local hp, ammo, carried = ply:Health(), ply:GetAmmo(), {}

        for _, w in ipairs(ply:GetWeapons()) do
            carried[w:GetClass()] = { w:Clip1(), w:Clip2() }
        end

        AGP.ShipRespawnPilot(ply)
        if (hp > 0) then ply:SetHealth(hp) end

        for _, w in ipairs(ply:GetWeapons()) do
            if (not carried[w:GetClass()]) then ply:StripWeapon(w:GetClass()) end
        end

        for class, clips in pairs(carried) do
            local w = ply:GetWeapon(class)
            if (not IsValid(w)) then w = ply:Give(class, true) end
            if (IsValid(w)) then w:SetClip1(clips[1]); w:SetClip2(clips[2]) end
        end

        timer.Simple(0, function() -- (AGP.ShipRespawnPilot puts his own ammo back in the same tick)
            if (not IsValid(ply)) then return end

            for id in pairs(ply:GetAmmo()) do
                if (not ammo[id]) then ply:SetAmmo(0, id) end
            end
        end)
    end

    function SWEP:ExitKino()
        if (IsValid(self.Owner)) then
            if (self.Owner:Alive()) then
                self.Owner:SetMoveType(MOVETYPE_WALK);
                self.Owner:SetObserverMode(OBS_MODE_NONE);
                AGPLeaveKinoView(self:GetOwner()); -- AGP: was self.Owner:Spawn()
                self.Owner:SetFOV(self.FOV,0.3);
                self.Owner:SetPos(self.StartPos + Vector(0,0,5)); -- whoa it repaired everythin
                self.Owner:Give("KinoRemote"); -- We get back our wep
                self.Owner:SelectWeapon("KinoRemote"); -- Finaly, we can hold our wep :)
                if self.OriginalAngles then
                    self.Owner:SetEyeAngles(self.OriginalAngles)
                end
            end
            self.Owner:SetViewEntity(self.Owner);
            self.Owner:SetNWBool("KActive", false);
            self.Owner:SetNWEntity("Kino", NULL);
        end
        if IsValid(self.KinoEntActive) then
            self.KinoEntActive:MoveKino(Vector(0,0,0));
            self.KinoEntActive.IsControlled = false;
            self.KinoEntActive.Remote = nil;
            self.KinoEntActive.Player = nil;
        end
        self.KinoEntActive = NULL;
    end

    --################### Dialing Computer @Suitch
    function SWEP:FindGate()
        local gate;
        local dist = self.Range;
        local pos = self.Owner:GetPos();
        for _,v in pairs(ents.FindByClass("stargate_*")) do
            if (not v.IsStargate or v.IsSupergate) then continue end
            local sg_dist = (pos - v:GetPos()):Length();
            if(dist >= sg_dist) then
                dist = sg_dist;
                gate = v;
            end
        end
        return gate;
    end

    --################# Open the menu @aVoN&Suitch
    function SWEP:OpenMenu(p)
        if(not IsValid(p)) then return end;
        local e = self:FindGate();
        if(not IsValid(e)) then return end;
        if(hook.Call("StarGate.Player.CanDialGate",GAMEMODE,p,e) == false) then return end;
        net.Start("StarGate.VGUI.Menu");
        net.WriteEntity(e);
        net.WriteInt(1,8);
        net.Send(p);
    end

    --################# Wire input - Relay to the gate @aVoN
    function SWEP:TriggerInput(k,v)
        local gate = self:FindGate();
        if(IsValid(gate)) then
            gate:TriggerInput(k,v);
        end
    end

    --################### Find Closest Rings @aVoN
    function SWEP:FindClosestRings()
        local ring;
        local pos = self.Owner:GetPos();
        local trace = util.TraceLine(util.GetPlayerTrace(self.Owner));
        local dist = 100;
        -- First check if we are aiming at a ring to call
        for _,v in pairs(ents.FindInSphere(trace.HitPos,100)) do
            if(v:GetClass() == "ring_base_ancient" and not v.Busy) then
                local len = (trace.HitPos-v:GetPos()):Length();
                if(len < dist) then
                    dist = len;
                    ring = v;
                end
            end
        end
        -- Not found a ring? Well, call closest
        if(not ring) then
            local dist = 500;
            for _,v in pairs(ents.FindByClass("ring_base_ancient")) do
                local len = (pos-v:GetPos()):Length();
                if(len < dist) then
                    dist = len;
                    ring = v;
                end
            end
        end
        return ring;
    end
end

if CLIENT then
    -- AGP: an own hook name - the plain "HideHud" can be another addon's too, and then one of the two stops
    hook.Add("HUDShouldDraw", "AGP.KinoRemote.HideHud", function(name)
        local ply = LocalPlayer()
        if not IsValid(ply) then return end -- Check if the player is valid

        if ply:GetNWBool("KActive") then
            if name == "CHudHealth" or name == "CHudBattery" then
                return false
            end
        end
    end)

    -- Inventory Icon
    if(file.Exists("materials/VGUI/weapons/kino_inventory.vmt","GAME")) then
        SWEP.WepSelectIcon = surface.GetTextureID("VGUI/weapons/kino_inventory");
    end
    -- Kill Icon
    if(file.Exists("materials/VGUI/weapons/kino_inventory.vmt","GAME")) then
        killicon.Add("KRD","VGUI/weapons/kino_inventory",Color(255,255,255));
    end

    SWEP.DrawAmmo	= false;
    SWEP.WepSelectIcon = surface.GetTextureID("VGUI/weapons/kino_inventory")

    local NV_Status = false

    local Color_Brightness		= 0.8
    local Color_Contrast 		= 1.1
    local Color_AddGreen		= -0.35
    local Color_MultiplyGreen 	= 0.028

    local AlphaAdd_Alpha 			= 1
    local AlphaAdd_Passes			= 1

    local matNightVision = Material("effects/nightvision")
    matNightVision:SetFloat( "$alpha", AlphaAdd_Alpha )

    local Color_Tab =
    {
        [ "$pp_colour_addr" ] 		= -1,
        [ "$pp_colour_addg" ] 		= Color_AddGreen,
        [ "$pp_colour_addb" ] 		= -1,
        [ "$pp_colour_brightness" ] = Color_Brightness,
        [ "$pp_colour_contrast" ]	= Color_Contrast,
        [ "$pp_colour_colour" ] 	= 0,
        [ "$pp_colour_mulr" ] 		= 0 ,
        [ "$pp_colour_mulg" ] 		= Color_MultiplyGreen,
        [ "$pp_colour_mulb" ] 		= 0
    }
    local CurScale = 0.2

    local Pressed = false;

    --################### Positions the viewmodel correctly @aVoN
    function SWEP:GetViewModelPosition(p,a)
        p = p - 10*a:Up() - 6*a:Forward() + 1*a:Right();
        a:RotateAroundAxis(a:Right(),32);
        a:RotateAroundAxis(a:Up(),4);
        return p,a;
    end

    --################### Tell a player how to use this @aVoN
    function SWEP:DrawHUD()

        local ply = LocalPlayer();
        local active = ply:GetNWBool("KActive")
        local kino = ply:GetNWEntity("Kino", ply);

        if (active == false) then -- Draw mode hud only, if we not flying with kino

            local mode = AGP.L("agp_mode_kino_point", "Kino point control");
            local int = self.Weapon:GetNWInt("Mode",1);

            if(int == 1) then
                mode = AGP.L("agp_mode_kino", "Kino control");
            elseif(int == 2) then
                mode = AGP.L("agp_mode_gate_dial", "Stargate dial control");
            elseif(int == 3) then
                mode = AGP.L("agp_mode_ring_dial", "Ring dial control");
            end

            draw.WordBox(8,ScrW()-228,ScrH()-120,AGP.L("agp_ui_primary", "Primary:") .. " "..mode,"Default",Color(0,0,0,80),Color(255,220,0,220));

        else

            surface.SetTexture(surface.GetTextureID("VGUI/HUD/kino/kino_back"));
            surface.SetDrawColor(255,255,255,255);
            surface.DrawTexturedRect(0,0,ScrW(),ScrH());

            if NV_Status == true then

                if CurScale < 0.995 then
                    CurScale = CurScale + math.Clamp(0.09, 0.01, 1) * (1 - CurScale)
                end

                Color_Tab[ "$pp_colour_brightness" ] = CurScale * Color_Brightness
                Color_Tab[ "$pp_colour_contrast" ] = CurScale * Color_Contrast
                DrawColorModify( Color_Tab )
                DrawMotionBlur( 0.05, 0.2, 0.023)
                DrawMaterialOverlay("models/shadertest/shader3.vmt", 0.0001)

                for i=1,AlphaAdd_Passes do
                    render.UpdateScreenEffectTexture()
                    render.SetMaterial( matNightVision )
                    render.DrawScreenQuad()
                end

            end

        end

    end

    local NWasDown = false -- AGP: N switches night vision once per press
    function SWEP:Think()
        local nDown = input.IsKeyDown(KEY_N)
        local nPress = nDown and not NWasDown
        NWasDown = nDown

        if  (!vgui.CursorVisible() and nPress and Pressed == false) then
            Pressed = true;
            NV_Status = not NV_Status;
            if (Pressed == true) then timer.Simple( 1, function() Pressed = false end) end
        end

        if NV_Status == true then

            local ply = LocalPlayer();
            local kino = ply:GetNWEntity("Kino", ply);

            local dlight = DynamicLight( LocalPlayer():EntIndex() )
            if  (dlight and IsValid(kino) and kino != ply) then
                local r, g, b, a = 255, 255, 255, 255
                dlight.Pos = kino:GetPos()
                dlight.r = r
                dlight.g = g
                dlight.b = b
                dlight.Brightness = 1
                dlight.Size = 512 * CurScale
                dlight.Decay = 512 * CurScale
                dlight.DieTime = CurTime() + 0.1
            end
        end
    end
end

-- AGP: CAP's own first-person model and animations, with the player's own hands laid onto its arm skeleton
-- (lua/autorun/agp_blueprint_arms.lua). GMod hand animations never fitted this item.
--
if (AGP and AGP.BlueprintArms) then
    AGP.BlueprintArms(SWEP, { vm = "models/Iziraider/kinoremote/v_kinoremote.mdl", hide = { "v_hands" }, arms = AGP.BlueprintRigs.izi })
end
