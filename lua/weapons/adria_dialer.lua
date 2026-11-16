-- AGP 2026-11-12: the loader's own SWEP table (a local one registered by a 0.1 s timer came after the spawn menu was
-- built: the weapon had no class name there yet and was left out of the weapons tab)

if (StarGate == nil or StarGate.CheckModule == nil or not StarGate.CheckModule("weapon")) then return end

if (SGLanguage != nil and SGLanguage.GetMessage != nil) then
    SWEP.PrintName = "Adria Dialer"
    SWEP.Category = SGLanguage.GetMessage("weapon_misc_cat")
    SWEP.ClassName = "adria_dialer"
end

list.Set("CAP.Weapon", SWEP.PrintName or "", SWEP)

SWEP.Author = "Nova Astral"
SWEP.Purpose = (AGP and AGP.L) and AGP.L("agp_wp_adria_dialer_p", "Dial the last address of a gate again") or "Dial the last address of a gate again"
SWEP.Instructions = (AGP and AGP.L) and AGP.L("agp_wp_adria_dialer_i", "Left click on a DHD: dial its last address again") or "Left click on a DHD: dial its last address again"
SWEP.DrawCrosshair = true
SWEP.SlotPos = 10
SWEP.Slot = 3
SWEP.Spawnable = false
SWEP.Weight = 1
SWEP.Primary.Ammo = "none" --This stops it from giving pistol ammo when you get the swep
SWEP.Primary.Automatic = true
SWEP.Secondary.Ammo = "none"
SWEP.Secondary.Automatic = true

-- AGP 2026-11-08: first person on Garry's Mod's hands, like the hand device (weapon_hand_device.lua): CAP's
-- v_hdevice.mdl holds only the device and a glove, no arm bones - no hands could show. GMod's bug bait animations carry
-- the hand, the pod is hidden and the device (w_hdevice) is drawn on the right hand by AGP.SGCWeapon below.
SWEP.ViewModel = "models/weapons/c_bugbait.mdl"
SWEP.ViewModelFOV = 54
SWEP.WorldModel = "models/w_hdevice.mdl"
SWEP.HoldType = "slam"
-- the same fit on the hand as the hand device's (measured there from c_bugbait / c_arms_citizen / w_hdevice)
if (AGP and AGP.SGCWeapon) then
    AGP.SGCWeapon(SWEP, {
        model = "models/w_hdevice.mdl",
        vmBone = "ValveBiped.Bip01_R_Hand", vmHand = true,
        vmPos = Vector(1.305, 0.858, 0.343), vmAng = Angle(-40.68, -18.75, -18.40),
    })
end

function SWEP:CanPrimaryAttack() return false end
function SWEP:CanSecondaryAttack() return false end
function SWEP:Holster() return true end
function SWEP:ShouldDropOnDie() return false end

function SWEP:Initialize()
    self:SetWeaponHoldType(self.HoldType)

    self:DrawShadow(false)

    self.Active = false
    self.tent = nil

    self.DHDs = { 
        "dhd_atlantis",
        "dhd_city",
        "dhd_concept",
        "dhd_infinity",
        "dhd_sg1",
        "dhd_universe"
    }
end

function SWEP:ButtonPress(v,ent)
    if(IsValid(ent)) then
        if(v >= 1 and v < 256) then
            local symbols = "A-Z1-9@#!*"

            if (GetConVar("stargate_group_system"):GetBool()) then
                symbols = "A-Z0-9@#*"
            end

            local char = string.char(v):upper()

            if (v>=128 and v<=137) then -- numpad 0-9
                char = string.char(v-80):upper() 
            elseif (v==139) then -- numpad *
                char = string.char(42):upper()
            end 

            if(char:find("["..symbols.."]")) then -- Only alphanumerical and the @, #
                ent:ButtonMode(char)
            end
        end
    end
end

function SWEP:StopDial()
    self.Active = false

    timer.Remove("adriadial"..self:EntIndex())
    timer.Remove("stopdial"..self:EntIndex())

    if(IsValid(self.tent)) then
        if(self.tent.ButtonsMode) then 
            self.tent:ResetButtons() 
        end

        self.tent.ButtonsMode = false
        self.tent:SetNWBool("ButtonsMode",false)

        if(not self.tent.GetWire or self.tent:GetWire("Disable DHD") <1) then -- AGP 2026-11-12: a target without Wire inputs (script error when the dialer was taken away while aimed at a player) 
            self.tent.Disabled = false
        else
            self.tent:SetNWBool("Disabled",true)
        end
    end
end

if SERVER then
    function SWEP:PrimaryAttack()
        if(self.Active == false) then
            self:SetNextPrimaryFire(CurTime()+1)

            local tr = self.Owner:GetEyeTrace()
            local ent = tr.Entity
            self.tent = tr.Entity

            if(IsValid(ent) and self.Owner:GetShootPos():Distance(tr.HitPos) < 50 and ent.IsDHD) then
                local gate = ent:FindGate()
                -- AGP 2026-11-08: a gate that never opened has Active = nil (set only by its first SetStatus) - it is
                -- not active either; the click did nothing and said nothing there. Nothing dialled before: say so
                -- instead of running the dial show for an empty address.
                local prev = IsValid(gate) and gate.OldDialedAddress
                if (IsValid(gate) and not gate.Active and (not prev or #prev == 0)) then
                    AGP.SayAs(self:GetOwner(), "info", "agp_adria_nolast", "This gate has not dialled anywhere yet - no address to repeat")
                    self:GetOwner():EmitSound("buttons/button18.wav",100,100)
                elseif (IsValid(gate) and not gate.Active) then
                    self.Active = true

                    ent.Disabled = true
                    ent.ButtonsMode = true
                    ent:SetNWBool("Disabled",false)
                    ent:SetNWBool("ButtonsMode",true)
                    
                    if not ent.ButtonsMode then
                        ent:ResetButtons()
                    end

                    timer.Create("adriadial"..self:EntIndex(),0.05,0,function()
                        local button = math.random(48,90) --0-Z

                        if(IsValid(ent)) then
                            self:ButtonPress(button,ent)
                        end
                    end)

                    timer.Create("stopdial"..self:EntIndex(),math.random(5,20),1,function()
                        if(IsValid(ent)) then
                            self:StopDial()

                            if(IsValid(gate)) then
                                gate:DialGate(gate.OldDialedAddress,true)
                            end
                        end
                    end)
                end
            else
                AGP.SayAs(self.Owner, "info", "agp_adria_baddhd", "This is not a valid DHD for the Adria dialer")
                self.Owner:EmitSound("buttons/button18.wav",100,100)
            end
        end
    end

    function SWEP:SecondaryAttack()
        if(self.Active == true) then
            self:StopDial()
        end
    end

    function SWEP:OnRemove() -- When the player dies
        timer.Remove("adriadial"..self:EntIndex())
        timer.Remove("stopdial"..self:EntIndex())

        if(IsValid(self.tent)) then
            if(self.tent.ButtonsMode) then 
                self.tent:ResetButtons() 
            end

            self.tent.ButtonsMode = false
            self.tent:SetNWBool("ButtonsMode",false)

            if(not self.tent.GetWire or self.tent:GetWire("Disable DHD") <1) then -- AGP 2026-11-12: a target without Wire inputs (script error when the dialer was taken away while aimed at a player) 
                self.tent.Disabled = false
            else
                self.tent:SetNWBool("Disabled",true)
            end
        end
    end
end

-- AGP 2026-11-12 (owner: "not really in the hand"): third person - CAP's world model is one rigid piece on one bone and
-- stood off the back of the hand on every body; the holder wears a copy whose pieces hang on the hand's and the
-- fingers' own bones (notes/models/agp_hdevice_build.py). The dropped weapon is CAP's model as before.
if (AGP and AGP.WorldMerged) then
    AGP.WorldMerged(SWEP, { model = "models/agp/w_hdevice_fit.mdl", convar = "agp_hdev_fix", stand_in = AGP.HandDeviceStandIn })
end
