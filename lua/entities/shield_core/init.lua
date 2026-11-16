--[[
	Shield Core
	Copyright (C) 2011 Madman07
]]--

if (StarGate==nil or StarGate.CheckModule==nil or not StarGate.CheckModule("devices")) then return end
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.Sounds={
	Engage=Sound("shields/shield_engage.mp3"),
	Disengage=Sound("shields/shield_disengage.mp3"),
	Fail={Sound("buttons/button19.wav"),Sound("buttons/combine_button2.wav")},
	Open=Sound("shields/shield_core.wav"),
};

-- AGP: per-core console commands of the old camera editor (removed again with the core)
local EDITOR_CMDS = { "SC_Apply", "SC_Close", "SC_Size", "SC_Angle", "SC_Pos" };

-----------------------------------INIT----------------------------------

function ENT:Initialize()

	self.Entity:SetModel("models/Madman07/destiny_emmiter/destiny_emmiter.mdl");

	self.Entity:SetName("Shield Core");
	self.Entity:PhysicsInit(SOLID_VPHYSICS);
	self.Entity:SetMoveType(MOVETYPE_VPHYSICS);
	self.Entity:SetSolid(SOLID_VPHYSICS);
	self.Entity:SetUseType(SIMPLE_USE);

	self.Immunity = false;
	self.Strength = 0;
	self.Mod = "models/Madman07/shields/sphere.mdl";
	self.Anim = false;
	self.ThinkTime = CurTime()+0.5;
	self.MenuData = "0 0 0 0 5 1";
	-- AGP: default bubble settings, so the core can be switched on (E menu, Wire, buttons) without opening the editor first
	self.SSize = Vector(512,512,512);
	self.Pos = Vector(0,0,0);
	self.Ang = Angle(0,0,0);
	self.Col = Vector(170,189,255);
	self.AGPPower = 0;
	self.AGPRegen = 1;

	self.Entity:SetNWBool("Kill", true); -- AGP: no editor preview open (was false: a preview effect could linger)
	self.Entity:SetNWVector("Size", self.SSize); -- AGP: was Vector(100,100,100), now the default above
	self.Entity:SetNWAngle("Ang", Angle(0,0,0));
	self.Entity:SetNWVector("Pos", Vector(0,0,0));
	self.Entity:SetNWVector("Col", Vector(170,189,255));
	self.Entity:SetNWString("Mod", self.Mod);
	self.Entity:SetNWString("MenuData", self.MenuData);
	self.Entity:SetNWBool("AGPDraw", false);

	self.StrengthMultiplier = {1,1,1}; -- The first argument is the strength multiplier, the second is the regeneration multiplier. The third value is the "raw" value n, set by SetMultiplier(n) This will get set by the TOOL
	self.Strength = 100; -- Start with 100% Strength by default
	self.EngageEnergy = StarGate.CFG:Get("shield","engage_energy",500); -- This energy will be needed to engage the shield. You will get it back, when the shield collapses
	self.ConsumeMultiplier = StarGate.CFG:Get("shield","consume_multiplier",1)*100; -- As higher this is, as more energy it will take when enabled
	self.RestoreMultiplier = StarGate.CFG:Get("shield","restore_multiplier",1); -- How fast can it restore it's health?
	self.StrengthConfigMultiplier = StarGate.CFG:Get("shield","strength_multiplier",1); -- Doing this value higher will make the shiels stronger (look at the config)

	self.RestoreThresold = StarGate.CFG:Get("shield","restore_thresold",15); -- Which powerlevel has the shield to reach again until it works again?
	self:AddResource("energy",1);
	self:CreateWireInputs("Activate","Toggle"); -- AGP: Toggle for Wire buttons (1 then 0)
	self:CreateWireOutputs("Active","Strength");
	self:SetWire("Strength",self.Strength);

	self.Pressed = false;

	self:SetNWInt("HUD_Enable", 0);
	self:SetNWInt("HUD_Percent", self.Strength);

	self.RegTime = 0;
	self.Depleted = false;
	self.AGPEngaged = false; -- the engage energy was taken (given back when switched off)

	self.PlyOldEyeAngle = Angle(0,0,0);

	-- AGP: the camera editor ("Advanced editor" in the E menu) only sets what the E menu cannot: position, angles,
	-- each size axis and the numpad key. OK keeps the shield on or off as it was.
	concommand.Add("SC_Apply"..self:EntIndex(),function(ply,cmd,args)
		if (not IsValid(self) or not self:AGPCanControl(ply)) then return end
		self:AGPCloseEditor();
		local b = self.AGPEditBackup;
		self.AGPEditBackup = nil;

		local key = tonumber(args[1]);
		if (key and IsValid(self.Owner)) then
			key = math.floor(key);
			if (self.AGPNumpad) then numpad.Remove(self.AGPNumpad) end -- one key, not one more binding per OK
			self.AGPNumpad = numpad.OnDown(self.Owner, key, "Toggle_Shield_Core", self.Entity);
			local d = string.Explode(" ",self.MenuData or "");
			d[5] = tostring(key);
			self.MenuData = string.format("%s %s %s %s %s %s", d[1] or "0", d[2] or "0", d[3] or "0", d[4] or "0", d[5], d[6] or "1");
			self.Entity:SetNWString("MenuData", self.MenuData);
		end

		-- a new size needs a new bubble; position and angles are followed by the bubble by itself
		if (IsValid(self.Shield) and (not b or b.SSize ~= self.SSize)) then self:AGPBuildShield() end
	end);

	concommand.Add("SC_Close"..self:EntIndex(),function(ply,cmd,args)
		if (not IsValid(self) or not self:AGPCanControl(ply)) then return end
		self:AGPCloseEditor();
		-- AGP: Close = cancel: the sliders changed the values live (for the preview), put them back
		local b = self.AGPEditBackup;
		self.AGPEditBackup = nil;
		if (b) then
			self.SSize, self.Pos, self.Ang = b.SSize, b.Pos, b.Ang;
			self.Entity:SetNWVector("Size", self.SSize);
			self.Entity:SetNWVector("Pos", self.Pos);
			self.Entity:SetNWAngle("Ang", self.Ang);
		end
	end);

	-- AGP: these took any text from any player (nil sizes broke the bubble): owner/admins only, numbers clamped
	local function nums(args, lo, hi, def)
		return math.Clamp(tonumber(args[1]) or def,lo,hi), math.Clamp(tonumber(args[2]) or def,lo,hi), math.Clamp(tonumber(args[3]) or def,lo,hi);
	end
	concommand.Add("SC_Size"..self:EntIndex(),function(ply,cmd,args)
		if (not IsValid(self) or not self:AGPCanControl(ply) or not self.AGPEditBackup) then return end
		self.SSize = Vector(nums(args,100,4096,512));
		self.Entity:SetNWVector("Size", self.SSize);
	end);

	concommand.Add("SC_Angle"..self:EntIndex(),function(ply,cmd,args)
		if (not IsValid(self) or not self:AGPCanControl(ply) or not self.AGPEditBackup) then return end
		self.Ang = Angle(nums(args,-180,180,0));
		self.Entity:SetNWAngle("Ang", self.Ang);
	end);

	concommand.Add("SC_Pos"..self:EntIndex(),function(ply,cmd,args)
		if (not IsValid(self) or not self:AGPCanControl(ply) or not self.AGPEditBackup) then return end
		self.Pos = Vector(nums(args,-512,512,0));
		self.Entity:SetNWVector("Pos", self.Pos);
	end);

	self:SpawnButton()

end

-- AGP: every client knows the core (the bubble graphic is drawn around it, also when the core is far away)
function ENT:UpdateTransmitState()
	return TRANSMIT_ALWAYS
end

function ENT:SpawnFunction( ply, tr )
	if (!tr.Hit) then return end

	local PropLimit = GetConVar("CAP_shieldcore_max"):GetInt()
	if(ply:GetCount("CAP_shieldcore")+1 > PropLimit) then
		ply:SendLua("GAMEMODE:AddNotify(SGLanguage.GetMessage(\"entity_limit_shield_core\"), NOTIFY_ERROR, 5); surface.PlaySound( \"buttons/button2.wav\" )");
		return
	end

	local ang = ply:GetAimVector():Angle(); ang.p = 0; ang.r = 0; ang.y = (ang.y+135) % 360;

	local ent = ents.Create("shield_core");
	ent:SetAngles(ang);
	ent:SetPos(tr.HitPos);
	ent:Spawn();
	ent:Activate();
	ent.Owner = ply;
	-- AGP: no longer frozen on spawn: it can be picked up and moved, the bubble follows it

	ply:AddCount("CAP_shieldcore", ent)
	return ent;
end

function ENT:SpawnButton()
	local button = ents.Create("shield_core_button");
	button:SetParent(self);
	button.Parent = self;
	button:SetPos(self:GetPos()-self:GetForward()*0.2+self:GetRight()*40+self:GetUp()*18)
	button:SetAngles(self:GetAngles()+Angle(0,0,0))
	button:DrawShadow(false)
	button:Spawn();
	button:Activate();
	self.Button = button
end

function ENT:OnRemove()
	StarGate.WireRD.OnRemove(self);
	if (self.AGPNumpad) then numpad.Remove(self.AGPNumpad) end -- AGP
	if IsValid(self.Shield) then self.Shield:Remove() end
	local id = self:EntIndex();
	for _, t in ipairs({ "Anim", "Sound", "SC_Press" }) do timer.Remove(t..id) end -- AGP: no timer left behind
	for _, c in ipairs(EDITOR_CMDS) do concommand.Remove(c..id) end
	if IsValid(self.Camera) then self.Camera:Remove(); end
	if IsValid(self.Player) then self.Player:SetViewEntity(self.Player); end
end

-- the old camera editor: position, angles, each size axis, numpad key (the shield stays as it is)
function ENT:TrueUse(ply)
	if (self.Busy or not self:AGPCanControl(ply)) then return end
	self.AGPEditBackup = { SSize = Vector(self.SSize.x, self.SSize.y, self.SSize.z), Pos = Vector(self.Pos.x, self.Pos.y, self.Pos.z), Ang = Angle(self.Ang.p, self.Ang.y, self.Ang.r) };

	if (not IsValid(self.Camera)) then
		self.Camera = ents.Create("prop_dynamic");
		self.Camera:SetModel("models/sandeno/naquadah_bottle.mdl");
		local pos = self:LocalToWorld(Vector(750,750,500));
		self.Camera:SetPos(pos);
		self.Camera:SetAngles((self:GetPos()-pos):Angle());
		self.Camera:Spawn();
		self.Camera:Activate();
		-- AGP: an invisible, not solid view point riding on the core (was a welded, frozen prop: the core could not move)
		self.Camera:SetNotSolid(true);
		self.Camera:SetMoveType(MOVETYPE_NONE);
		self.Camera:SetColor(Color(0,0,0,0));
		self.Camera:SetRenderMode(RENDERMODE_TRANSALPHA);
		self.Camera:DrawShadow(false);
		self.Camera:SetParent(self);
		if CPPI and IsValid(self.Owner) and self.Camera.CPPISetOwner then self.Camera:CPPISetOwner(self.Owner) end
	end

	self.PlyOldEyeAngle = ply:EyeAngles();
	ply:SetViewEntity(self.Camera);

	self.Entity:SetNWBool("Kill", false);

	umsg.Start("ShieldCorePanel",ply)
	umsg.Entity(self.Entity);
	umsg.End()
	self.Player = ply;
	ply.ShieldCore = self;

	local fx = EffectData();
		fx:SetEntity(self.Entity);
		fx:SetOrigin(self:GetPos());
	util.Effect("shield_core_preview",fx,true,true);
end

function ENT:AGPCloseEditor()
	if IsValid(self.Player) then self.Player:SetViewEntity(self.Player) end
	self.Player = nil;
	self.Busy = false;
	self.Entity:SetNWBool("Kill", true);
	if IsValid(self.Camera) then self.Camera:Remove() end
end

function ENT:EmmiterAnimation(open)
	self.Anim = true;
	self:SetNWBool("ShouldClip", true);
	local id = self:EntIndex();
	timer.Remove("Anim"..id);
	if open then
		self.Entity:SetModel("models/Madman07/destiny_emmiter/destiny_emmiter_anim.mdl");
		local seq = self:LookupSequence("Open");
		self:ResetSequence(seq);
		timer.Create( "Anim"..id, 7, 1, function()
			if (not IsValid(self)) then return end
			self.Anim = false;
			self:SetNWBool("ShouldClip", false);
		end);
	else
		local seq = self:LookupSequence("Close");
		self:ResetSequence(seq);
		timer.Create( "Anim"..id, 7, 1, function()
			if (not IsValid(self)) then return end
			self.Anim = false;
			self:SetNWBool("ShouldClip", false);
			self.Entity:SetModel("models/Madman07/destiny_emmiter/destiny_emmiter.mdl");
		end);
	end
	timer.Create( "Sound"..id, 0.4, 1, function() if (IsValid(self)) then self:EmitSound(self.Sounds.Open,100,100); end end);
end

--################# AGP: on / off / collapse / restore in one place #################
-- States: off; on (bubble up); depleted (collapsed, emitter stays open, comes back by itself when recharged).
-- User/Wire/numpad switching goes through Status() (7 s lock while the emitter moves). Collapse, restore and running
-- out of energy are forced (never blocked by the lock, never repeated every think).

function ENT:AGPIsOn()
	return (IsValid(self.Shield) and self.Shield.Enabled) or self.Depleted == true;
end

function ENT:AGPLock()
	self.Pressed = true;
	timer.Create("SC_Press" .. self:EntIndex(), 7, 1, function() if IsValid(self) then self.Pressed = false end end);
end

-- the bubble up or down (with sound and Wire), nothing else
function ENT:AGPSetBubble(on, nosound)
	local b = self.Shield;
	if (not IsValid(b)) then return end
	if (on) then
		if (not b.Enabled) then
			b:Status(true);
			if (not nosound) then self:EmitSound(self.Sounds.Engage,90,math.random(90,110)) end
		end
		self:SetWire("Active",1);
	else
		if (b.Enabled) then
			b:Status(false);
			if (not nosound) then self:EmitSound(self.Sounds.Disengage,90,math.random(90,110)) end
		end
		self:SetWire("Active",0);
	end
	self:ShowOutput(b.Enabled, self.Atlantis);
end

-- strength gone: the bubble collapses, comes back by itself (Think) once recharged
function ENT:AGPCollapse()
	if (self.Depleted or not (IsValid(self.Shield) and self.Shield.Enabled)) then return end
	self.Depleted = true;
	self.Shield.Depleted = true;
	self.Shield:SetNWBool("depleted",true); -- For the traceline class - Clientside
	self:AGPSetBubble(false);
	self.AGPRestoreAt = CurTime() + 3; -- at least 3 s down: no on/off flicker
	self:ShowOutput(false);
end

function ENT:AGPRestore()
	if (not self.Depleted or not IsValid(self.Shield)) then return end
	self.Depleted = false;
	self.Shield.Depleted = false;
	self.Shield:SetNWBool("depleted",false);
	self:AGPSetBubble(true);
end

-- status: true = on, false = off. force: not blocked by the emitter lock (energy loss)
function ENT:Status(status,nosound,force)
	-- AGP: the bubble used to exist only after OK in the camera editor (reached through a hidden button), so E, Wire
	-- and buttons did nothing on a new core. Now it is made from the current settings when it is switched on.
	if (status) then
		if (not IsValid(self.Shield)) then
			self:AGPBuildShield();
			if (not IsValid(self.Shield)) then return end
		end
		if (self:AGPIsOn()) then return end
		if (self.Pressed and not force) then -- the emitter is still moving (7 s): say so instead of doing nothing
			self:AGPTell("agp_sc_busy","Shield core: the emitter is still moving, try again in a few seconds.");
			return
		end
		local energy = self:GetResource("energy",self.EngageEnergy);
		self.ConsumeAmmount = math.ceil(((self.Shield.Radius)^2*math.pi*4)/200000); -- Instead of doing this calculation very second, do it here
		self.ExtraConsume = math.exp(math.Clamp(self.StrengthMultiplier[3]*1.3,0.2,600));
		if ((self.Atlantis or self.Strength >= 1) and energy >= self.EngageEnergy) then
			-- Taking the enagage energy, you will get back later (when turning off the shield)
			self:ConsumeResource("energy",self.EngageEnergy);
			self.AGPEngaged = true;
			self:AGPLock();
			self:AGPSetBubble(true, nosound);
			self:EmmiterAnimation(true); -- Open emmiter - shield active
			self:SetSkin(1);
			return
		end
		-- Fail animation
		self:EmitSound(self.Sounds.Fail[1],90,math.random(90,110));
		self:EmitSound(self.Sounds.Fail[2],90,math.random(90,110));
		-- AGP: tell the player why it did not come up
		if (energy < self.EngageEnergy) then
			self:AGPTell("agp_sc_no_energy","Shield core: not enough energy (needs %s, has %s). Connect it to a power source.",math.ceil(self.EngageEnergy),math.floor(energy));
		else
			self:AGPTell("agp_sc_recharging","Shield core: still recharging (%s%%).",math.floor(self.Strength));
		end
	else
		if (not self:AGPIsOn()) then return end -- already off: nothing (no fail sound loop)
		if (self.Pressed and not force) then
			self:AGPTell("agp_sc_busy","Shield core: the emitter is still moving, try again in a few seconds.");
			return
		end
		-- Give back the energy, we took when it was enagaged
		if (self.AGPEngaged) then
			self:SupplyResource("energy",self.EngageEnergy);
			self.AGPEngaged = false;
		end
		local wasDepleted = self.Depleted;
		self.Depleted = false;
		if (IsValid(self.Shield)) then
			self.Shield.Depleted = false;
			self.Shield:SetNWBool("depleted",false);
		end
		self:AGPSetBubble(false, nosound or wasDepleted); -- Disable Shield
		self:SetSkin(0);
		self:EmmiterAnimation(false); -- Close emmiter - shield inactive
		self:AGPLock();
		self:ShowOutput(false);
	end
end

function ENT:Think(ply)

	-- AGP: a Wire Activate that came while the emitter was moving is carried out now
	if (self.WireWanted ~= nil and not self.Pressed) then
		local want = self.WireWanted;
		self.WireWanted = nil;
		if (want ~= self:AGPIsOn()) then self:Status(want) end
	end

	if (self.ThinkTime < CurTime()) then
		self.ThinkTime = CurTime()+0.5
		local b = self.Shield;
		local enabled = IsValid(b) and b.Enabled or false;
		if self.Atlantis then	-- infinite strength if we have power
			if (self.Depleted) then self:AGPRestore(); enabled = IsValid(b) and b.Enabled or false; end -- (collapsed before it was switched to Atlantis type)
			self:ShowOutput(enabled, true);
			if (enabled) then
				local energy = self:GetResource("energy");
				if(energy <= 1000) then -- minimal energy for making it work
					self:Status(false,false,true); -- AGP: forced, once (was every think, also when off: fail sound loop)
				end
			end
		else
			if (CurTime() > self.RegTime) then self:Regenerate(enabled); end
			if (enabled and self.Strength < 1) then
				self:AGPCollapse();
				enabled = false;
			end
			if(self.Depleted) then
				-- Reenable shielt - It was depleted before (But alter the Thresold, so people wont have it up so fast again or need to wait ages)
				if(self.Strength >= math.Clamp(self.RestoreThresold/self.StrengthMultiplier[2],3,40) and CurTime() >= (self.AGPRestoreAt or 0)) then
					self:AGPRestore();
				end
			elseif(enabled and self.HasResourceDistribution and self.ConsumeMultiplier ~= 0) then
				-- Consume energy
				local energy = self:GetResource("energy");

				-- Make the shield consume more power depending on it's strength
				local take_energy = (self.ConsumeAmmount or 1)*(self.ExtraConsume or 1)*self.ConsumeMultiplier
				self:ConsumeResource("energy",math.Clamp(take_energy,1,math.max(energy,1)));
				if(energy <= take_energy) then -- no energy - shut down it
					self:Status(false,false,true);
				end
			end
			self:ShowOutput(IsValid(b) and b.Enabled or false);
		end
	end

	if self.Anim then
		self:NextThink(CurTime());
		return true
	else
		self:NextThink(CurTime()+0.5);
		return true
	end
end

function ENT:ShowOutput(enabled, atl)
	local add = 0;
	if(enabled) then
		add = 1;
	end
	if(self.Depleted) then
		add = 2;
	end
	self:SetNWInt("HUD_Enable", add);
	if atl then
		self:SetNWInt("HUD_Percent", 100);
		self:SetWire("Strength",100);
	else
		self:SetNWInt("HUD_Percent", self.Strength);
		self:SetWire("Strength",math.floor(self.Strength));
	end
end

--################# Set's the strengthg multiplier which is necessary for the shields regeneration time and strength @aVoN
function ENT:SetMultiplier(n)
	local n = math.Clamp(n or 0,-5,5); -- Backwarts compatibility and idiot-proof
	if(n > 0) then
		n = 1 + n;
		self.StrengthMultiplier[1] = n
		self.StrengthMultiplier[2] = n^1.5
	else
		n = 1/(1 - n);
		self.StrengthMultiplier[1] = n^1.5;
		self.StrengthMultiplier[2] = n;
	end
	self.Strength = math.Clamp((self.StrengthMultiplier[3]/n)*self.Strength,0,100); -- This avoids cheating
	self.StrengthMultiplier[3] = n;
end

--################# Shield got hit - Take strength @aVoN
function ENT:Hit(strength,normal,pos)
	-- Calculate strenght-taking multiplier: Are we a shield, which is not moving? If so, we are many times stronger than a shield of a ship which is moving.
	local divisor = 1;
	if(self.Entity:GetVelocity():Length() < 5) then
		divisor = StarGate.CFG:Get("shield","stationary_shield_multiplier",5);
	end

	-- Take strength if not atlantis, otherwise take energy
	if self.Atlantis then
		-- Consume energy
		local energy = self:GetResource("energy");

		-- Make the shield consume more power depending on hit strength
		local take_energy = math.Clamp(200*math.Clamp(strength,1,40)/(self.StrengthMultiplier[1]*self.StrengthConfigMultiplier*divisor),1,10000)*StarGate.CFG:Get("shield_core","atlantis_hit",50);
		self:ConsumeResource("energy",math.Clamp(take_energy,1,math.max(energy,1)));
	else
		self.Strength = math.Clamp(self.Strength-2*math.Clamp(strength,1,20)/(self.StrengthMultiplier[1]*self.StrengthConfigMultiplier*divisor),0,100);
	end

	self.RegTime = CurTime()+2.5;

	if(StarGate.CFG:Get("shield","apply_force",false)) then
		-- Make us bounce around
		local phys = self:GetPhysicsObject();
		if (IsValid(phys) and normal and pos) then
			phys:ApplyForceOffset(-1*normal*strength*100*phys:GetMass()/self.StrengthMultiplier[1],pos);
		end
	end
end

--################# Reset it's strength @aVoN
function ENT:Regenerate(enabled)
	if(self.Strength < 100) then
		local multiplier = 1;
		-- Disabled shields can regenrate 2 times faster!
		if(not (enabled or self.Depleted)) then
			multiplier = multiplier*2.5;
		end
		-- Consume energy when restoring the strength
		if(StarGate.HasResourceDistribution) then
			local energy = self:GetResource("energy");
			local speed = math.Clamp(energy/5000,1,4); -- Can make up to 4 times faster to regenerate with enough power connected (ZPMs, resource Caches etc)
			multiplier = math.floor(multiplier*speed)*(self.AGPRegen or 1); -- AGP: recharge speed from the menu (faster costs more energy)
			local take_energy = multiplier*20
			if(take_energy > energy) then return end;
			self:ConsumeResource("energy",take_energy);
		else
			-- For those without lifesupport: Make the shield regenerate a bit faster (Due to request)
			multiplier = multiplier*2*(self.AGPRegen or 1); -- AGP: recharge speed from the menu
		end
		multiplier = multiplier*(self.RestoreMultiplier/self.StrengthMultiplier[2]); -- Multiplier from the config and with the StrengthMultiplier
		self.Strength = math.Clamp(self.Strength+multiplier,0,100);
	end
end

--################# Wire input @aVoN
function ENT:TriggerInput(k,v)
	if(k=="Activate") then
		-- AGP: only act on a change; while the emitter moves (7 s) remember the wanted state (Think carries it out)
		local want = ((v or 0) >= 1);
		if (self.Pressed) then
			self.WireWanted = want;
		elseif (want ~= self:AGPIsOn()) then
			self.WireWanted = nil;
			self:Status(want);
		end
	elseif(k=="Toggle" and (v or 0) > 0) then -- AGP: a Wire button sends 1 then 0: toggle once per press
		self:Toggle();
	end
end

numpad.Register("Toggle_Shield_Core",
	function(p,e)
		if not IsValid(e) then return end;
		e.AGPUser = p; e.AGPUserTime = CurTime();
		e:Toggle(); -- AGP: also works before the bubble exists
	end
);

--################# AGP: on/off, E menu, settings #################

util.AddNetworkString("AGP_ShieldCoreMenu");
util.AddNetworkString("AGP_ShieldCoreSet");

ENT.AGPModels = {"models/Madman07/shields/sphere.mdl","models/Madman07/shields/box.mdl","models/Madman07/shields/atlantis.mdl"};

-- switch on/off (E menu, Wire Toggle, numpad, buttons and devices that "use" the core); a collapsed shield is on
-- (it comes back by itself), so toggling it switches it off
function ENT:Toggle()
	self:Status(not self:AGPIsOn());
end

-- the owner (Lua field or CPPI) or an admin; a core without owner (left the server) is free for everyone
function ENT:AGPCanControl(ply)
	if (not IsValid(ply) or not ply:IsPlayer()) then return false end
	if (ply:IsAdmin()) then return true end
	local own = self.Owner;
	if (not IsValid(own) and self.CPPIGetOwner) then own = self:CPPIGetOwner() end
	return (not IsValid(own)) or own == ply;
end

-- a chat line for the player who just switched it (E menu, numpad), not for Wire/automatic changes
function ENT:AGPTell(key,fallback,...)
	local ply = self.AGPUser;
	if (IsValid(ply) and (self.AGPUserTime or 0) + 2 > CurTime() and AGP and AGP.Say) then
		AGP.Say(ply,key,fallback,...);
		self.AGPUserTime = 0; -- one line per press
	end
end

-- E: a small menu for the owner/admins. A button, Wire User or other device that uses the core toggles it.
function ENT:Use(activator,caller)
	if (not IsValid(activator) or not activator:IsPlayer() or (IsValid(caller) and caller ~= activator and not caller:IsPlayer())) then
		self:Toggle();
		return
	end
	if ((self.AGPNextUse or 0) > CurTime()) then return end
	self.AGPNextUse = CurTime() + 0.5;
	if (not self:AGPCanControl(activator)) then
		if (AGP and AGP.Say) then AGP.Say(activator,"agp_sc_not_owner","Only the owner of this shield core or an admin can use it.") end
		return
	end
	self:AGPSendMenu(activator);
end

-- immunity, owner and look to the bubble (the client needs them for the wall and the graphic)
function ENT:AGPSyncBubble()
	self:SetNWBool("AGPDraw", self.Draw and true or false);
	local b = self.Shield;
	if (not IsValid(b)) then return end
	local own = self.Owner;
	if (not IsValid(own) and self.CPPIGetOwner) then own = self:CPPIGetOwner() end
	b:SetNWBool("Immunity", self.Immunity and true or false);
	b:SetNWEntity("Own", IsValid(own) and own or NULL);
	b:SetNWVector("Col", self.Col or Vector(170,189,255));
	b:CollisionRulesChanged();
end

-- makes (or remakes) the bubble from the current settings; keeps it as it was (on, off or collapsed, no engage cost
-- again), and who was allowed inside stays allowed. keepOff: switch it off first.
function ENT:AGPBuildShield(keepOff)
	if (keepOff and self:AGPIsOn()) then self:Status(false,true,true) end
	local old = self.Shield;
	local wasUp = IsValid(old) and old.Enabled;
	local inherit = wasUp and old.AGPAllowed or nil;
	if (IsValid(old)) then old:Remove() end
	self.Shield = nil;
	self.SSize = self.SSize or Vector(512,512,512);
	self.Pos = self.Pos or Vector(0,0,0);
	self.Ang = self.Ang or Angle(0,0,0);

	local a = ents.Create("shield_core_buble");
	if (not IsValid(a)) then return end
	a:SetModel("models/hunter/blocks/cube025x025x025.mdl");
	a:SetPos(self:LocalToWorld(self.Pos));
	a:SetAngles(self:GetAngles()+self.Ang);
	a.Parent = self;
	if CPPI and IsValid(self.Owner) and a.CPPISetOwner then a:CPPISetOwner(self.Owner) end
	a:SetNWVector("Col",self.Entity:GetNWVector("Col",Vector(170,189,255)));
	a:Spawn();
	a:Activate();
	a:SetCollisionScale(self.Mod, self.SSize/512);
	-- AGP: not welded any more (the weld to the frozen bubble held the core in place); the bubble follows the core
	a:SetNotSolid(true); -- off until switched on (it stood solid but "off" after the editor's OK)
	a:SetNWEntity("AGPCore", self.Entity);
	self:SetNWEntity("AGPBubble", a);
	self.Shield = a;
	self:AGPSyncBubble();
	if (self.Depleted) then
		a.Depleted = true;
		a:SetNWBool("depleted",true);
	elseif (wasUp) then
		self.ConsumeAmmount = math.ceil(((a.Radius)^2*math.pi*4)/200000);
		a:Status(true, inherit);
	end
	return a;
end

-- settings saved in MenuData ("power immunity draw atlantis key regen"), used by the old editor and dupes
function ENT:AGPApplyMenuData()
	local d = string.Explode(" ",self.MenuData or "");
	self.AGPPower = math.Clamp(tonumber(d[1]) or 0,-5,5);
	self:SetMultiplier(self.AGPPower);
	self.Immunity = util.tobool(tonumber(d[2]));
	self.Draw = util.tobool(tonumber(d[3]));
	self.Atlantis = util.tobool(tonumber(d[4])) and self.HasResourceDistribution;
	self.AGPRegen = math.Clamp(tonumber(d[6]) or 1,0.25,4);
	self:AGPSyncBubble();
end

function ENT:AGPWriteMenuData()
	local d = string.Explode(" ",self.MenuData or "");
	self.MenuData = string.format("%s %d %d %d %s %s",tostring(self.AGPPower or 0),self.Immunity and 1 or 0,self.Draw and 1 or 0,self.Atlantis and 1 or 0,d[5] or "5",tostring(self.AGPRegen or 1));
	self.Entity:SetNWString("MenuData",self.MenuData);
end

function ENT:AGPSendMenu(ply)
	local mod = 1;
	for i,m in ipairs(self.AGPModels) do if (m == self.Mod) then mod = i end end
	net.Start("AGP_ShieldCoreMenu");
	net.WriteEntity(self.Entity);
	net.WriteBool(self:AGPIsOn());
	net.WriteBool(self.Depleted and true or false);
	net.WriteFloat(self.Strength or 0);
	net.WriteFloat(self.AGPPower or 0);
	net.WriteFloat(self.AGPRegen or 1);
	net.WriteBool(self.Immunity and true or false);
	net.WriteBool(self.Draw and true or false);
	net.WriteBool(self.Atlantis and true or false);
	net.WriteUInt(mod,2);
	net.WriteVector(self.SSize or Vector(512,512,512));
	net.WriteVector(self.Col or Vector(170,189,255));
	net.WriteBool(self.HasResourceDistribution and true or false);
	net.WriteFloat(self:GetResource("energy",0) or 0);
	net.WriteFloat(self.EngageEnergy or 0);
	net.Send(ply);
end

net.Receive("AGP_ShieldCoreSet",function(len,ply)
	local e = net.ReadEntity();
	local act = net.ReadUInt(2);
	if (not IsValid(e) or e:GetClass() ~= "shield_core" or not e.AGPCanControl or not e:AGPCanControl(ply)) then return end
	if (ply:GetPos():Distance(e:GetPos()) > 3000) then return end
	if (act == 1) then -- on/off
		e.AGPUser = ply; e.AGPUserTime = CurTime();
		e:Toggle();
	elseif (act == 2) then -- apply settings
		local function num(x,lo,hi,def) -- no NaN/inf from a client
			if (type(x) ~= "number" or x ~= x or x == math.huge or x == -math.huge) then return def end
			return math.Clamp(x,lo,hi);
		end
		local mod = math.Clamp(net.ReadUInt(2),1,3);
		local size = net.ReadVector();
		local col = net.ReadVector();
		local power = num(net.ReadFloat(),-5,5,0);
		local regen = num(net.ReadFloat(),0.25,4,1);
		local imm, draw, atl = net.ReadBool(), net.ReadBool(), net.ReadBool();
		size = Vector(math.Round(num(size.x,100,4096,512)),math.Round(num(size.y,100,4096,512)),math.Round(num(size.z,100,4096,512)));
		col = Vector(math.Round(num(col.x,0,255,170)),math.Round(num(col.y,0,255,189)),math.Round(num(col.z,0,255,255)));
		local rebuild = (size ~= e.SSize or e.AGPModels[mod] ~= e.Mod);
		e.SSize = size; e:SetNWVector("Size",size);
		e.Mod = e.AGPModels[mod]; e:SetNWString("Mod",e.Mod);
		e.Col = col; e:SetNWVector("Col",col);
		if (power ~= e.AGPPower) then e.AGPPower = power; e:SetMultiplier(power) end
		e.AGPRegen = regen;
		e.Immunity = imm;
		e.Draw = draw;
		e.Atlantis = atl and e.HasResourceDistribution;
		e:AGPWriteMenuData();
		if (IsValid(e.Shield) and rebuild) then e:AGPBuildShield() end
		e:AGPSyncBubble();
		if (AGP and AGP.Say) then AGP.Say(ply,"agp_sc_applied","Shield core: settings applied.") end
	elseif (act == 3) then -- the old editor with the camera (position, angles, each size axis, numpad key)
		e:TrueUse(ply);
	end
end);


function ENT:PreEntityCopy()
	local dupeInfo = {}
	if IsValid(self.Entity) then
		dupeInfo.EntID = self.Entity:EntIndex()
	end

	dupeInfo.SSize = self.SSize;
	dupeInfo.Ang = self.Ang;
	dupeInfo.Pos = self.Pos;
	dupeInfo.Col = self.Col;
	dupeInfo.Mod = self.Mod;
	dupeInfo.MenuData = self.MenuData;

	duplicator.StoreEntityModifier(self, "SCDupeInfo", dupeInfo)
	StarGate.WireRD.PreEntityCopy(self)
end
duplicator.RegisterEntityModifier( "SCDupeInfo" , function() end)

function ENT:PostEntityPaste(ply, Ent, CreatedEntities)
	if (StarGate.NotSpawnable(Ent:GetClass(),ply)) then self.Entity:Remove(); return end
	if (IsValid(ply)) then
		local PropLimit = GetConVar("CAP_shieldcore_max"):GetInt();
		if(ply:GetCount("CAP_shieldcore")+1 > PropLimit) then
			ply:SendLua("GAMEMODE:AddNotify(SGLanguage.GetMessage(\"entity_limit_shield_core\"), NOTIFY_ERROR, 5); surface.PlaySound( \"buttons/button2.wav\" )");
			self.Entity:Remove();
			return
		end
	end

	local dupeInfo = Ent.EntityMods and Ent.EntityMods.SCDupeInfo or {} -- AGP: no error on a dupe without the data

	if dupeInfo.EntID then
		self.Entity = CreatedEntities[ dupeInfo.EntID ]
	end

	-- AGP: settings never edited were nil in old dupes: keep the defaults then
	self.SSize = dupeInfo.SSize or self.SSize or Vector(512,512,512);
	-- AGP: the same limits as the menu (a 0 or huge size from a dupe went straight into the physics mesh)
	if (isvector(self.SSize)) then
		local function c(v) v = tonumber(v) or 512 if (v ~= v) then v = 512 end return math.Round(math.Clamp(v, 100, 4096)) end
		self.SSize = Vector(c(self.SSize.x), c(self.SSize.y), c(self.SSize.z))
	else
		self.SSize = Vector(512,512,512)
	end
	self.Ang = dupeInfo.Ang or self.Ang or Angle(0,0,0);
	self.Pos = dupeInfo.Pos or self.Pos or Vector(0,0,0);
	self.Col = dupeInfo.Col or self.Col or Vector(170,189,255);
	self.Mod = dupeInfo.Mod or self.Mod;
	self.MenuData = dupeInfo.MenuData or self.MenuData;

	self.Entity:SetNWVector("Size", self.SSize);
	self.Entity:SetNWAngle("Ang", self.Ang);
	self.Entity:SetNWVector("Pos", self.Pos);
	self.Entity:SetNWVector("Col", self.Col);
	self.Entity:SetNWString("Mod", self.Mod);
	self.Entity:SetNWString("MenuData", self.MenuData);
	if (IsValid(ply)) then
		self.Owner = ply;
		ply:AddCount("CAP_shieldcore", self.Entity)
	end
	self:AGPApplyMenuData(); -- AGP: strength, immunity, bubble look, Atlantis type and recharge speed come back with the dupe
	self.Strength = 100; -- a pasted core starts full (SetMultiplier lowers it, against cheating while running)
	StarGate.WireRD.PostEntityPaste(self,ply,Ent,CreatedEntities)

end

if (StarGate and StarGate.CAP_GmodDuplicator) then
	duplicator.RegisterEntityClass( "shield_core", StarGate.CAP_GmodDuplicator, "Data" )
end
