--[[
	###################################
	StarGate with Group System
	Created by AlexALX (c) 2011
	###################################
]]
-- fixing file.FindInLua function on mac
-- file name should start at z_ or it will not help correctly
if SERVER then
    AddCSLuaFile()
end

if (Gmod13Lib == nil) then
    include("a_gmod13.lua")
end
--  Maybe not needed anymore? not sure. But this file still needed for include a_gmod13 on linux server first.