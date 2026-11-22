--[[
	-- ~ Fading Door STool ~
	-- ~ Based on Conna's, but this time it works. ~
	-- ~ Lexi ~
--]]

--[[ Tool Related Settings ]]--


TOOL.Name = "#tool.shield_door.name"
TOOL.Category="Tech";
TOOL.Tab = "Stargate"; -- AGP: was "CAP", which made a stray extra tab

TOOL.AddToMenu = false; -- Tell gmod not to add it. We will do it manually later!
TOOL.Command=nil;
TOOL.ConfigName="";

TOOL.ClientConVar["key"] = "5"
TOOL.ClientConVar["toggle"] = "0"
TOOL.ClientConVar["reversed"] = "0"
TOOL.ClientConVar["r"] = 255;
TOOL.ClientConVar["g"] = 255;
TOOL.ClientConVar["b"] = 255;

local function checkTrace(tr)
	return (tr.Entity and tr.Entity:IsValid() and not (tr.Entity:IsPlayer() or tr.Entity:IsNPC() or tr.Entity:IsVehicle() or tr.HitWorld));
end

-- AGP: own names for the dupe modifier, numpad functions, message, undo and remove hook. The Janus and the Shield
-- door tool (and the common Workshop "Fading Door" tool) all used "Fading Door", "Fading Doors onUp/onDown",
-- "FadingDoorHurrah!": this file loads last and won, so a duped Janus door came back as a Shield door (invisible prop,
-- black bubble) and a new Janus door said "Shield door has been created!".
local MODIFIER = "AGP Shield Door";
local MESSAGE = "AGPShieldDoorMade";
local NUM_UP, NUM_DOWN = "AGP Shield Door onUp", "AGP Shield Door onDown";

if (CLIENT) then
	usermessage.Hook(MESSAGE, function()
		GAMEMODE:AddNotify(AGP.L("agp_shield_door_created", "Shield door has been created!"), NOTIFY_GENERIC, 10);
		surface.PlaySound ("ambient/water/drip" .. math.random(1, 4) .. ".wav");
	end);
	-- AGP: the names the tool menu and tool gun screen look up (the old "Tool_..." ones are not used any more)
	language.Add("tool.shield_door.name", AGP and AGP.L and AGP.L("agp_tool_shield_door_name", "Shield Doors") or "Shield Doors")
	language.Add("tool.shield_door.desc", AGP and AGP.L and AGP.L("agp_tool_shield_door_desc", "Makes anything into a Shield Door") or "Makes anything into a Shield Door")
	language.Add("tool.shield_door.0", AGP and AGP.L and AGP.L("agp_tool_shield_door_0", "Click on something to make it a Shield Door.") or "Click on something to make it a Shield Door.")
	language.Add("Tool_shield_door_name", "Shield Doors");
	language.Add("Tool_shield_door_desc", "Makes anything into a Shield door");
	language.Add("Tool_shield_door_0", "Click on something to make it a Shield door.");
	language.Add("Undone_shield_door", "Undone Shield Door");

	function TOOL:BuildCPanel()
		self:AddControl("ComboBox",{
			Label="Presets",
			MenuButton=1,
			Folder="shield_door",
			Options={
				["Goa'uld"] = {
					shield_door_r = 255,
					shield_door_g = 128,
					shield_door_b = 59,
				},
				["Asgard"] = {
					shield_door_r = 170,
					shield_door_g = 189,
					shield_door_b = 255,
				},
				["Alteran"] = {
					shield_door_r = 124,
					shield_door_g = 255,
					shield_door_b = 189,
				},
			},
		});
		self:AddControl("CheckBox", {Label = AGP.L("agp_ui_reversed_starts_invisible_becomes_solid", "Reversed (starts invisible, becomes solid)"), Command = "shield_door_reversed"});
		self:AddControl("CheckBox", {Label = AGP.L("agp_ui_toggle_active", "Toggle Active"), Command = "shield_door_toggle"});
		self:AddControl("Numpad",   {Label = "Button", ButtonSize = "22", Command = "shield_door_key"});
		self:AddControl("Color",{
			Label = "Color",
			Red = "shield_door_r",
			Green = "shield_door_g",
			Blue = "shield_door_b",
			ShowAlpha = 0,
			ShowHSV = 1,
			ShowRGB = 1,
			Multiplier = 255,
		});
	end

	-- AGP: was "TOOL.LeftClick = checkTrace": called as self:LeftClick(tr), checkTrace got the tool as its trace and
	-- returned nil, so the client never drew the tool-gun beam. Same check as the server now.
	function TOOL:LeftClick(tr)
		return checkTrace(tr) and true or false;
	end

	return;
end
umsg.PoolString(MESSAGE);

local function fadeActivate(self)
	self.fadeActive = true;
	self:SetNWBool("StopBuble", true);
	self:SetRenderMode(RENDERMODE_NONE)
	self:DrawShadow(false)
	self:SetNotSolid(true)
	local phys = self:GetPhysicsObject();
	if (IsValid(phys)) then
		self.fadeMoveable = phys:IsMoveable();
		phys:EnableMotion(false);
	end
	if (WireLib) then
		Wire_TriggerOutput(self,  "FadeActive",  1);
	end
end

local function fadeDeactivate(self)
	self.fadeActive = false;
	self:SetRenderMode(RENDERMODE_NONE)
	self:DrawShadow(false);
	self:SetNotSolid(false);

	self:SetNWBool("StopBuble", false);
	self:SetNWString("DoorModel", self:GetModel())
	self:SetNWVector("DoorColor", Vector(self.r, self.g, self.b))
 	local fx = EffectData();
		fx:SetEntity(self);
	util.Effect("const_shield",fx,true,true);

	local phys = self:GetPhysicsObject();
	if (IsValid(phys)) then
		phys:EnableMotion(self.fadeMoveable or false);
	end
	if (WireLib) then
		Wire_TriggerOutput(self,  "FadeActive",  0);
	end
end

local function fadeToggleActive(self)
	if (self.fadeActive) then
		self:fadeDeactivate();
	else
		self:fadeActivate();
	end
end

local function onUp(ply, ent)
	if (not (ent:IsValid() and ent.fadeToggleActive and not ent.fadeToggle)) then
		return;
	end
	ent:fadeToggleActive();
end
numpad.Register(NUM_UP, onUp);

local function onDown(ply, ent)
	if (not (ent:IsValid() and ent.fadeToggleActive)) then
		return;
	end
	ent:fadeToggleActive();
end
numpad.Register(NUM_DOWN, onDown);

local function doWireInputs(ent)
	local inputs = ent.Inputs;
	if (not inputs) then
		Wire_CreateInputs(ent, {"Fade"});
		return;
	end
	local names, types, descs = {}, {}, {};
	local num;
	for _, data in pairs(inputs) do
		num = data.Num;
		names[num] = data.Name;
		types[num] = data.Type;
		descs[num] = data.Desc;
	end
	table.insert(names, "Fade");
	WireLib.AdjustSpecialInputs(ent, names, types, descs);
end

local function doWireOutputs(ent)
	local outputs = ent.Outputs;
	if (not outputs) then
		Wire_CreateOutputs(ent, {"FadeActive"});
		return;
	end
	local names, types, descs = {}, {}, {};
	local num;
	for _, data in pairs(outputs) do
		num = data.Num;
		names[num] = data.Name;
		types[num] = data.Type;
		descs[num] = data.Desc;
	end
	table.insert(names, "FadeActive");
	WireLib.AdjustSpecialOutputs(ent, names, types, descs);
end

local function TriggerInput(self, name, value, ...)
	if (name == "Fade") then
		if (value == 0) then
			if (self.fadePrevWireOn) then
				self.fadePrevWireOn = false;
				if (not self.fadeToggle) then
					self:fadeToggleActive();
				end
			end
		else
			if (not self.fadePrevWireOn) then
				self.fadePrevWireOn = true;
				self:fadeToggleActive();
			end
		end
	elseif (self.fadeTriggerInput) then
		return self:fadeTriggerInput(name, value, ...);
	end
end

local function PreEntityCopy(self)
	local info = WireLib.BuildDupeInfo(self)
	if (info) then
		duplicator.StoreEntityModifier(self, "WireDupeInfo", info);
	end
	if (self.fadePreEntityCopy) then
		self:fadePreEntityCopy();
	end
end

local function PostEntityPaste(self, ply, ent, ents)
	if (self.EntityMods and self.EntityMods.WireDupeInfo) then
		WireLib.ApplyDupeInfo(ply, self, self.EntityMods.WireDupeInfo, function(id) return ents[id]; end);
	end
	if (self.fadePostEntityPaste) then
		self:fadePostEntityPaste(ply, ent, ents);
	end
end


local function onRemove(self)
	numpad.Remove(self.fadeUpNum);
	numpad.Remove(self.fadeDownNum);
end

--Fer Duplicator
local function dooEet(ply, ent, stuff)
	if (ent.isFadingDoor) then
		ent:fadeDeactivate();
		onRemove(ent)
	else
		ent.isFadingDoor = true;
		ent.fadeActivate = fadeActivate;
		ent.fadeDeactivate = fadeDeactivate;
		ent.fadeToggleActive = fadeToggleActive;
		ent:CallOnRemove(MODIFIER, onRemove); -- AGP: own name (was "Fading Doors")
		if (WireLib) then
			doWireInputs(ent);
			doWireOutputs(ent);
			ent.fadeTriggerInput = ent.fadeTriggerInput or ent.TriggerInput;
			ent.TriggerInput = TriggerInput;
			if (not ent.IsWire) then -- Dupe Support
				ent.fadePreEntityCopy = ent.PreEntityCopy;
				ent.PreEntityCopy = PreEntityCopy;
				ent.fadePostEntityPaste = ent.PostEntityPaste;
				ent.PostEntityPaste = PostEntityPaste;
			end
		end
	end
	ent.fadeUpNum = numpad.OnUp(ply, stuff.key, NUM_UP, ent);
	ent.fadeDownNum = numpad.OnDown(ply, stuff.key, NUM_DOWN, ent);
	ent.fadeToggle = stuff.toggle;
	-- AGP: white when no colour came along (nil made a black bubble)
	ent.r = stuff.r or 1;
	ent.g = stuff.g or 1;
	ent.b = stuff.b or 1;
	if (stuff.reversed) then
		ent:fadeActivate();
	else
		ent:fadeDeactivate();
	end
	duplicator.StoreEntityModifier(ent, MODIFIER, stuff);
	return true;
end

duplicator.RegisterEntityModifier(MODIFIER, dooEet);

-- AGP: old saves/dupes. Both our door tools stored their doors as "Fading Door" (and read Conna's older
-- "FadingDoor"). The stored data tells which door it was: only the Shield door stored a colour (r, g, b); no colour =
-- a Janus door. Exception: if another addon (the Workshop Fading Door tool) had registered the name before us, doors
-- without a colour go back to it (its data looks just like a Janus door's). The same block is in janus_door.lua:
-- whichever file loads first registers it, each puts its own door function into AGP.OldFadingDoor.
AGP = AGP or {};
AGP.OldFadingDoor = AGP.OldFadingDoor or {};
local OLD = AGP.OldFadingDoor;
OLD.shield = dooEet;
if (not OLD.registered) then
	OLD.registered = true;
	OLD.foreign = {};
	for _, name in ipairs({ "Fading Door", "FadingDoor" }) do
		OLD.foreign[name] = duplicator.EntityModifiers and duplicator.EntityModifiers[name];
	end
	local function hasColour(d) return d.r ~= nil or d.g ~= nil or d.b ~= nil end
	local function restore(name, ply, ent, stuff)
		if (hasColour(stuff) and OLD.shield) then
			OLD.shield(ply, ent, stuff);
		elseif (OLD.janus) then
			OLD.janus(ply, ent, stuff);
		else
			return;
		end
		duplicator.ClearEntityModifier(ent, name); -- it is stored under our own name now
	end
	OLD.handlers = {};
	OLD.handlers["Fading Door"] = function(ply, ent, data)
		data = data or {};
		if (not hasColour(data) and OLD.foreign["Fading Door"]) then return OLD.foreign["Fading Door"](ply, ent, data) end
		restore("Fading Door", ply, ent, data);
	end;
	OLD.handlers["FadingDoor"] = function(ply, ent, data)
		if (OLD.foreign["FadingDoor"]) then return OLD.foreign["FadingDoor"](ply, ent, data) end
		data = data or {};
		restore("FadingDoor", ply, ent, { key = data.Key, toggle = data.Toggle, reversed = data.Inverse, r = data.r, g = data.g, b = data.b });
	end;
	for name, fn in pairs(OLD.handlers) do duplicator.RegisterEntityModifier(name, fn) end
end

local function doUndo(undoData, ent)
	if (IsValid(ent)) then
		onRemove(ent);
		ent:fadeDeactivate();
		ent:SetRenderMode(RENDERMODE_NORMAL)
		ent:DrawShadow(true);
		ent:SetNWBool("StopBuble", true);
		ent.isFadingDoor = false;
		if (WireLib) then
			ent.TriggerInput = ent.fadeTriggerInput;
			if (ent.Inputs) then
				Wire_Link_Clear(ent, "Fade");
				ent.Inputs['Fade'] = nil;
				WireLib._SetInputs(ent);
			end if (ent.Outputs) then
				local port = ent.Outputs['FadeActive']
				if (port) then
					for i,inp in ipairs(port.Connected) do -- From WireLib.lua: -- fix by Syranide: unlinks wires of removed outputs
						if (inp.Entity:IsValid()) then
							Wire_Link_Clear(inp.Entity, inp.Name)
						end
					end
				end
				ent.Outputs['FadeActive'] = nil;
				WireLib._SetOutputs(ent);
			end
		end
	end
end

function TOOL:LeftClick(tr)
	if (not checkTrace(tr)) then
		return false;
	end
	local ent = tr.Entity;
	local ply = self:GetOwner();
	dooEet(ply, ent, {
		key      = self:GetClientNumber("key");
		toggle   = self:GetClientNumber("toggle") == 1;
		reversed = self:GetClientNumber("reversed") == 1;
		r = self:GetClientNumber("r")/255;
		g = self:GetClientNumber("g")/255;
		b = self:GetClientNumber("b")/255;
	});
	undo.Create("shield_door"); -- AGP: own names (were fading_door / FadingDoorHurrah!); "Undone_shield_door" is above
		undo.AddFunction(doUndo, ent);
		undo.SetPlayer(ply);
	undo.Finish();

	SendUserMessage(MESSAGE, ply);
	return true
end
