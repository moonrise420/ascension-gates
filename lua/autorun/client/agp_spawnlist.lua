--[[
	Ascension Gates: spawn menu list for props that had no function in CAP Enhanced or EAP
	(models in the packs that no entity or tool used). Generated from a build script
]]
local GROUPS = {
    {"boba_fett", {
        "models/boba_fett/p90/attachments/kull-zapper.mdl",
        "models/boba_fett/p90/attachments/laserex.mdl",
        "models/boba_fett/tac/w_tacthrown.mdl",
    }},
    {"iziraider", {
        "models/iziraider/aurora/aurora.mdl",
        "models/iziraider/kino/kino.mdl",
        "models/iziraider/shields/1x1x1.mdl",
        "models/iziraider/shields/1x2x1.mdl",
        "models/iziraider/shields/2x2x1.mdl",
        "models/iziraider/shields/2x2x2.mdl",
        "models/iziraider/shields/2x3x2.mdl",
        "models/iziraider/shields/3x3x2.mdl",
        "models/iziraider/shields/3x3x3.mdl",
        "models/iziraider/shields/3x4x3.mdl",
        "models/iziraider/shields/4x4x3.mdl",
        "models/iziraider/shields/4x4x4.mdl",
        "models/iziraider/shields/4x5x4.mdl",
        "models/iziraider/shields/5x5x4.mdl",
        "models/iziraider/shields/5x5x5.mdl",
        "models/iziraider/shields/5x6x5.mdl",
        "models/iziraider/shields/6x6x5.mdl",
        "models/iziraider/shields/6x6x6.mdl",
        "models/iziraider/shields/6x7x6.mdl",
        "models/iziraider/shields/7x7x6.mdl",
        "models/iziraider/shields/7x7x7.mdl",
        "models/iziraider/shields/7x8x7.mdl",
        "models/iziraider/shields/8x8x7.mdl",
        "models/iziraider/shields/8x8x8.mdl",
        "models/iziraider/zpmhub/zpmhub.mdl",
    }},
    {"madman07", {
        "models/madman07/f302/gate_clamp.mdl",
        "models/madman07/main_weapon/main_small.mdl",
        "models/madman07/wall_decoration/light1.mdl",
    }},
    {"metal", {
        "models/metal/bar.mdl",
        "models/metal/mediumoredeposit.mdl",
        "models/metal/miner1.mdl",
        "models/metal/ore.mdl",
        "models/metal/smalloredeposit.mdl",
    }},
    {"pg_props", {
        "models/pg_props/pg_stargate/pg_atlantis_test.mdl",
        "models/pg_props/pg_stargate/pg_latern.mdl",
        "models/pg_props/pg_stargate/pg_shot_used.mdl",
        "models/pg_props/pg_weapons/pg_60cal_gun.mdl",
        "models/pg_props/pg_weapons/pg_60cal_stand.mdl",
        "models/pg_props/pg_weapons/pg_replicator_v.mdl",
        "models/pg_props/pg_weapons/pg_sta_granate.mdl",
        "models/pg_props/pg_weapons/pg_test_weapon.mdl",
        "models/pg_props/pg_weapons/pg_wraithblaster.mdl",
    }},
    {"ori", {
        "models/agp/props/agp_ori_pyre.mdl",
    }},
    {"props_phx", {
        "models/props_phx/misc/smallcannonball.mdl",
    }},
    {"sgorlin", {
        "models/sgorlin/stargate_shielde_orlin.mdl",
    }},
    {"soren", {
        "models/soren/asuran_console/asuran_console.mdl",
        "models/soren/asuran_core/asuran_core.mdl",
    }},
    {"the_sniper_9", {
        "models/the_sniper_9/universe/stargate/innersymbols1-18.mdl",
        "models/the_sniper_9/universe/stargate/innersymbols19-36.mdl",
    }},
    {"goauld", {
        "models/agp/props/agp_crystal_tray.mdl",
    }},
    {"zup", {
        "models/zup/ramps/brick_01_small.mdl",
        "models/zup/ramps/sgc_ramp_small.mdl",
        "models/zup/stargate/atlantis_shield_.mdl",
    }},
}

-- a model is listed only when its whole set is there: with the .mdl alone (no vertex file) the game draws a red ERROR -
-- the small ore deposit of the pack was like that. AGP.ModelComplete is used by the other prop lists too.
AGP = AGP or {}
function AGP.ModelComplete(m)
    local stem = m:sub(1, -5)
    return file.Exists(m, "GAME") and file.Exists(stem .. ".vvd", "GAME") and (file.Exists(stem .. ".dx90.vtx", "GAME") or file.Exists(stem .. ".vtx", "GAME"))
end

hook.Add("PopulatePropMenu", "AGP_PropSpawnlist", function()
    local contents = {}
    for _, g in ipairs(GROUPS) do
        contents[#contents + 1] = {type = "header", text = g[1]}
        for _, m in ipairs(g[2]) do
            if AGP.ModelComplete(m) then contents[#contents + 1] = {type = "model", model = m} end
        end
    end
    spawnmenu.AddPropCategory("agp_props", "Ascension Gates Props", contents, "icon16/star.png")
end)
