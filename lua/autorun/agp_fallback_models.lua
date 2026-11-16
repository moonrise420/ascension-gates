--[[
	Ascension Gates (2026-11-08): a few CAP parts use models that only Wiremod brings (the numpad of the Dakara
	building, the Dakara button and the ship hangar's panels, the flat thruster of the Jumper and Tel'tak buttons, the
	hangar's LED). Without Wiremod they were ERROR models. AGP.ModelOr(model, fallback) keeps the Wiremod model when it
	is there and otherwise uses a model from the base game. Wiremod is not required by our addon.
]]
AddCSLuaFile()
AGP = AGP or {}

AGP.WireFallbackModels = {
	["models/beer/wiremod/numpad.mdl"] = "models/props_lab/keypad.mdl",
	["models/jaanus/thruster_flat.mdl"] = "models/maxofs2d/button_05.mdl",
	["models/led2.mdl"] = "models/maxofs2d/button_01.mdl",
}

function AGP.ModelOr(model, fallback)
	fallback = fallback or AGP.WireFallbackModels[model]
	if (not fallback or util.IsValidModel(model)) then return model end
	return fallback
end
