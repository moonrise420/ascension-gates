--[[
	Goa'uld door panel (Ascension Gates) One
	half of an agp_goauld_door: a real model with its own collision (models/agp/hatak/props/door_<w>x<h>x<t>.mdl),
	parented to its door, which slides it into the wall. E on it works the door. Not in the spawn menu;
	doors create their panels.
]]
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Goa'uld Door Panel"
ENT.Author = "Ascension Gates"
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_OPAQUE

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "Side")   -- 1 or -1: which way it slides
end

-- where the panel stands in its door at the door's current opening (door space)
function ENT:SlidePos(door)
	local half = door:GetDoorWidth() / 2
	return Vector(0, self:GetSide() * (half / 2 + door:OpenFraction() * half * 0.98), 0)
end

if SERVER then
	AddCSLuaFile()

	function ENT:Initialize()
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_NONE)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetUseType(SIMPLE_USE)
		local ph = self:GetPhysicsObject()
		if (IsValid(ph)) then ph:EnableMotion(false) end
		self.NoDissolve = true
	end

	function ENT:Use(ply)
		local door = self:GetParent()
		if (not IsValid(door) or not IsValid(ply) or not ply:IsPlayer()) then return end
		local ship = door.AGPShip
		if (IsValid(ship) and ship.DoorPanelUse) then ship:DoorPanelUse(door, ply) else door:Use(ply, ply) end
	end

	function ENT:PhysgunPickup() return false end
	function ENT:CanTool() return false end
	function ENT:CanProperty() return false end
end

if CLIENT then
	-- smooth on screen: the door's opening is known here every frame (the server moves the panel only each tick)
	function ENT:Draw()
		local door = self:GetParent()
		if (not IsValid(door) or not door.OpenFraction) then self:DrawModel() return end
		local par = door:GetParent()   -- a door on a cloaking ship (Ha'tak hull) fades with it
		if (IsValid(par) and par.CloakAlpha and par:CloakAlpha() < 0.5) then return end
		if (door:GetOpened() and door:OpenFraction() >= 1) then return end   -- fully in the wall
		local half = door:GetDoorWidth() / 2
		-- the panel disappears into the wall: cut it off at the edges of the doorway
		local ydir = -door:GetRight()
		local c = door:GetPos()
		local oldClip = render.EnableClipping(true)
		render.PushCustomClipPlane(-ydir, (-ydir):Dot(c + ydir * half))
		render.PushCustomClipPlane(ydir, ydir:Dot(c - ydir * half))
		self:SetRenderOrigin(door:LocalToWorld(self:SlidePos(door)))
		self:SetupBones()
		self:DrawModel()
		self:SetRenderOrigin()
		render.PopCustomClipPlane()
		render.PopCustomClipPlane()
		render.EnableClipping(oldClip)
	end
end
