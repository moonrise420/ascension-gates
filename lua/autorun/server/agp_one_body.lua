-- Ascension Gates (2026-11-12, owner: "when I die suddenly there are 2 dead bodies"): a death leaves one body.
-- Normal deaths already do (tested: kill, bullet, blast, fall, with a weapon out). The cases that left a second one:
--  * a stunned player (Zat-like stun bolts, TAC, Wraith stun bomb lie him down as a prop_ragdoll and hide him) who
--    dies of something else: the game's death body appeared next to the stun body, which stayed for seconds
--  * the Zat's second hit turned the victim's body into a server-side one - and left that switched on for every
--    later death of that player
-- A dead player in a sarcophagus is handled there (entities/sarcophagus.lua: no un-hiding of a dead player).
local function stunBodyGone(ply)
    if (not IsValid(ply)) then return end
    local rag = ply:GetNWEntity("StunRagdoll")
    if (ply.Stunned or IsValid(rag)) then
        ply.Stunned = nil                       -- (first: the stun body's own remove hook would kill him once more)
        ply:SendLua("LocalPlayer().Stunned = nil")
        ply:SetNWEntity("StunRagdoll", NULL)
        ply.AGPHiddenAtDeath = true
        ply:Freeze(false)
        ply:SetNotSolid(false)
        ply:DrawViewModel(true)
        ply:DrawWorldModel(true)
        if (IsValid(rag)) then rag:Remove() end
        hook.Remove("EntityTakeDamage", "StunRagdollDamage" .. ply:EntIndex())
    end
end
-- (2026-11-12, the owner's own case: "shot the Zat at the ground at my feet, and when I died there were 2 bodies" -
-- reproduced with suite bodieszat) the Zat's killing hit makes the engine leave a server-side body (it is the one the
-- third hit vaporises) - and the gamemode adds its normal death body as well. The normal one goes.
local function oneZatBody(ply)
    if (not IsValid(ply) or not ply.GetShouldServerRagdoll or not ply:GetShouldServerRagdoll()) then return end
    local r = ply:GetRagdollEntity()
    if (IsValid(r)) then r:Remove() end
end
hook.Add("PostPlayerDeath", "AGP.OneBody", function(ply)
    oneZatBody(ply)
    timer.Simple(0, function() oneZatBody(ply) end)
end)
hook.Add("PlayerDeath", "AGP.OneBody", stunBodyGone)
hook.Add("PlayerSilentDeath", "AGP.OneBody", stunBodyGone)

hook.Add("PlayerSpawn", "AGP.OneBody", function(ply)
    if (ply.SetShouldServerRagdoll) then ply:SetShouldServerRagdoll(false) end   -- (the Zat sets it for its vaporising hit)
    -- hidden when he died (stunned, in a sarcophagus): visible again in the new life. Un-hiding the DEAD player would
    -- draw his standing model next to the body.
    if (ply.AGPHiddenAtDeath) then ply.AGPHiddenAtDeath = nil; ply:SetNoDraw(false) end
end)
