-- Ascension Gates: Goa'uld power hub tool (next to the ZPM tools).
-- Left click: Goa'uld power hub (power core on a brass hub, 4 crystal arms). Right click: Goa'uld power crystal -
-- on a hub it goes straight onto a free arm. Charge slider: how full new crystals are.
TOOL.Tab = "SpaceGrid"
TOOL.Category = "Energy"
TOOL.Name = "#tool.agp_goauld_power.name"
TOOL.Command = nil
TOOL.ConfigName = ""
TOOL.ClientConVar["charge"] = 100

if CLIENT then
	language.Add("tool.agp_goauld_power.name", "Goa'uld Power Hub + Crystals")
	language.Add("tool.agp_goauld_power.desc", "Left click: power hub. Right click: power crystal (aimed at a hub arm: onto that arm)")
	language.Add("tool.agp_goauld_power.left", "Goa'uld power hub (power core with 4 crystal arms)")
	language.Add("tool.agp_goauld_power.right", "Goa'uld power crystal (on a hub: straight onto a free arm)")
end
TOOL.Information = { { name = "left" }, { name = "right" } }

local function spawn(tool, tr, cls)
	if (CLIENT) then return true end
	local ply = tool:GetOwner()
	local st = scripted_ents.GetStored(cls)
	if (not st or not tr.Hit) then return false end
	local e = st.t:SpawnFunction(ply, tr, cls)
	if (not IsValid(e)) then return false end
	if (e.CPPISetOwner) then e:CPPISetOwner(ply) end
	undo.Create(cls); undo.AddEntity(e); undo.SetPlayer(ply); undo.Finish()
	ply:AddCleanup("sents", e)
	return e
end

function TOOL:LeftClick(tr)
	if (IsValid(tr.Entity) and tr.Entity:IsPlayer()) then return false end
	return spawn(self, tr, "agp_goauld_power_hub") and true or false
end

function TOOL:RightClick(tr)
	if (IsValid(tr.Entity) and tr.Entity:IsPlayer()) then return false end
	local e = spawn(self, tr, "agp_goauld_power_crystal")
	if (CLIENT or not e) then return e and true or false end
	e:SetEnergy(e.MaxEnergy * math.Clamp(self:GetClientNumber("charge", 100), 0, 100) / 100)
	local hub = tr.Entity
	if (IsValid(hub) and hub:GetClass() == "agp_goauld_power_core") then
		for _, h in ipairs(ents.FindInSphere(hub:GetPos(), 60)) do if (h:GetClass() == "agp_goauld_power_hub") then hub = h end end
	end
	if (IsValid(hub) and hub:GetClass() == "agp_goauld_power_hub") then hub:Touch(e) end
	return true
end

function TOOL.BuildCPanel(panel)
	panel:Help(AGP.L("agp_ui_a_goauld_power_core_crystals_on", "A Goa'uld power core: crystals on the hub's arms give their energy to the power network the hub is linked to (PowerGrid Connector or Spacebuild/RD). The core pulses brighter the more charged crystals it holds."))
	panel:NumSlider(AGP.L("agp_ui_crystal_charge", "Crystal charge (%)"), "agp_goauld_power_charge", 0, 100, 0)
end
