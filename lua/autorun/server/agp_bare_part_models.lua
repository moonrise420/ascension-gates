--[[
	Ascension Gates (2026-11-12): parts that a tool or a parent entity places get their model from that tool or
	parent. Created bare (a script, a test, another addon) they had none and the game drew a red ERROR. Owner: "dont
	these have looks individual themselfs? and why not give them this look?" - so each of them now has its own
	normal model as the default: the tool's default choice or the one its parent gives it (the list and where each
	comes from: notes/bare_part_models_2026-11-12.json). A model set before Spawn - what tools and parents do - is
	left alone. mobile_gate has no model at all (the Attero device's invisible carrier of an event horizon): bare, it
	is not drawn.
]]
local MODELS = {
	agp_door_panel = "models/agp/hatak/props/door_57x112x10.mdl",
	atlantis_light = "models/madman07/wall_decoration/decoration1.mdl",
	bearing = "models/iziraider/gatebearing/bearing.mdl",
	brazier = "models/boba_fett/props/brazier.mdl",
	cap_console = "models/markjaw/atlantis_console/console.mdl",
	cap_doors = "models/cryptalchemy_models/destiny/bridge_door/bridge_door.mdl",
	cap_doors_contr = "models/iziraider/destinybutton/destinybutton.mdl",
	cap_doors_frame = "models/cryptalchemy_models/destiny/bridge_door/bridge_door_frame.mdl",
	cloaking_generator = "models/props_c17/clock01.mdl",
	control_panel = "models/madman07/ring_panel/goauld_panel.mdl",
	dart_harvester = "models/miriam/minidrone/minidrone.mdl",
	floorchevron = "models/the_sniper_9/universe/stargate/floorchevron.mdl",
	jamming_device = "models/micropro/shield_gen.mdl",
	mobile_dhd = "models/props_c17/clock01.mdl",
	ramp = "models/iziraider/ramp1/ramp1.mdl",
	ramp_2 = "models/iziraider/ramp2/ramp2.mdl",
	ring_panel = "models/madman07/ring_panel/goauld_panel.mdl",
	sg_console = "models/markjaw/atlantis_console/console.mdl",
	sg_turret_daedalus = "models/madman07/daedalus/turret.mdl",
	sg_turret_part = "models/madman07/main_weapon/main_turn.mdl",
	sgc_monitor = "models/props_lab/monitor01a.mdl",
	sgu_ramp = "models/markjaw/sgu_ramp.mdl",
	shield_generator = "models/micropro/shield_gen.mdl",
	ship_hangar_button = "models/props_lab/keypad.mdl",
	staff_stationary_part = "models/iziraider/staffweapon/socket.mdl",
	staff_weapon_glider = "models/votekick/s_turret.mdl",
	tokra_emmiter = "models/madman07/tokra_shield/generator.mdl",
	tokra_key = "models/madman07/tokra_shield/controller.mdl",
	tollan_disabler = "models/iziraider/disabler/disabler.mdl",
	wraith_harvester = "models/props_c17/pottery03a.mdl",
}
local HIDDEN = { mobile_gate = true }

local function bare(self)
	local m = self:GetModel()
	return (not m) or m == "" or m:lower() == "models/error.mdl"
end

local function wrap()
	for class, mdl in pairs(MODELS) do
		local st = scripted_ents.GetStored(class)
		if (st and st.t and not st.t.AGPBareModel) then
			local eff = scripted_ents.Get(class)   -- (with what it inherits: the class itself may have no Initialize of its own)
			local old = eff and eff.Initialize
			st.t.AGPBareModel = mdl
			st.t.Initialize = function(self, ...)
				if (bare(self)) then self:SetModel((AGP and AGP.ModelOr) and AGP.ModelOr(mdl) or mdl) end
				if (old) then return old(self, ...) end
			end
		end
	end
	for class in pairs(HIDDEN) do
		local st = scripted_ents.GetStored(class)
		if (st and st.t and not st.t.AGPBareHidden) then
			local eff = scripted_ents.Get(class)
			local old = eff and eff.Initialize
			st.t.AGPBareHidden = true
			st.t.Initialize = function(self, ...)
				if (bare(self)) then self:SetNoDraw(true); self:DrawShadow(false) end
				if (old) then return old(self, ...) end
			end
		end
	end
end
hook.Add("PostGamemodeLoaded", "AGP.BarePartModels", wrap)
hook.Add("InitPostEntity", "AGP.BarePartModels", wrap)
hook.Add("OnReloaded", "AGP.BarePartModels", wrap)
