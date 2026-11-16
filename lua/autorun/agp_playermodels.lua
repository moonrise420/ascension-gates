--[[
	Ascension Gates: the Tau'ri player models. This release works with CAP's player models (owner 2026-11-12): CAP's
	own four are registered by CAP Enhanced (stargate/shared/misc.lua: SG soldier, Anubis guard, Wraith, Prior); here
	come four copies of CAP's SG soldier (ViktorK's model: his body, head, hands and skeleton) in each Tau'ri group's
	cloth, with the series' shoulder patches (notes/models/agp_cap_soldier_build.py). The same four models are the
	Tau'ri NPC groups (agp_npcs.lua).
	Our own player models (2026-11-09 .. 11) are parked outside the pack for a later update
	(Code/parked/player_models_2026-11-12, with the code that registered them).
]]
-- the first-person arms: GMod's own soldier arms (c_arms_dod: a long sleeve buttoned at the wrist), with textures of
-- ours (notes/models/agp_hands_build.py): the server below puts the group's sleeve on them; the soldier wears black
-- gloves
AGP = AGP or {}
AGP_ARMS = "models/weapons/c_arms_dod.mdl"
local CAP_SLEEVE = { sg = "bdu_green", sgc = "bdu_navy", atl = "atl", dst = "dst" }
-- each group: CAP's soldier, and the same soldier with the head of one of GMod's own women (owner 2026-11-12: "female
-- head on male body is a good workaround for now"). Atlantis: the flag on the left shoulder is the skin (USA, Canada).
for _, v in ipairs({ { "sg", "SG Team" }, { "sgc", "SGC Personnel" }, { "atl", "Atlantis Expedition" }, { "dst", "Destiny Crew" } }) do
    for i = 0, 3 do
        local mdl = "models/player/agp_cap/cap_soldier_" .. v[1] .. (i > 0 and ("_f" .. i) or "") .. ".mdl"
        local name = v[2] .. (i > 0 and (" (female " .. i .. ")") or "")
        if (file.Exists(mdl, "GAME")) then
            list.Set("PlayerOptionsModel", name, mdl)
            player_manager.AddValidModel(name, mdl)
            player_manager.AddValidHands(name, AGP_ARMS, 0, "0")
        end
    end
end

function AGP.ArmsLook(ply)
    local cap = string.lower(ply:GetModel() or ""):match("models/player/agp_cap/cap_soldier_(%a+)")
    if (not cap or not CAP_SLEEVE[cap]) then return end
    return "models/agp/hands/sleeve_" .. CAP_SLEEVE[cap], "models/agp/hands/skin_glove_black"
end

if (SERVER) then
    local function dress(ply, hands)
        if (not IsValid(hands)) then return end
        hands:SetSubMaterial()   -- (the hands entity stays when the player changes model: no sleeve of ours on others)
        local sleeve, skin = AGP.ArmsLook(ply)
        if (not sleeve) then return end
        if (hands:GetModel() ~= AGP_ARMS) then hands:SetModel(AGP_ARMS) end
        hands:SetSkin(0); hands:SetBodyGroups("0")
        for i, m in ipairs(hands:GetMaterials() or {}) do
            m = string.lower(m)
            if (m:find("sleeve", 1, true)) then hands:SetSubMaterial(i - 1, sleeve)        -- v_axis_sleeve, us_sleeve
            elseif (m:find("v_hand", 1, true)) then hands:SetSubMaterial(i - 1, skin) end
        end
        return true
    end
    hook.Add("PlayerSetHandsModel", "AGP.Arms", function(ply, hands) return dress(ply, hands) end)
    -- (the SGC's green or navy uniform is the player's skin, chosen after spawn: the sleeve follows)
    timer.Create("AGP.ArmsSkin", 2, 0, function()
        for _, ply in ipairs(player.GetHumans()) do
            local h = ply:GetHands()
            if (IsValid(h) and h:GetModel() == AGP_ARMS) then
                local key = ply:GetModel() .. "#" .. ply:GetSkin()
                if (ply.AGPArmsKey ~= key) then ply.AGPArmsKey = key; dress(ply, h) end
            end
        end
    end)
end
