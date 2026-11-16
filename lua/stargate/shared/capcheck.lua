/*
	###################################
	StarGate with Groups System
	Created by AlexALX (c) 2011
	###################################
*/
StarGate_Group = StarGate_Group or {};

local status = "Loaded";
StarGate_Group.Error = false;
StarGate_Group.ErrorMSG = {};
StarGate_Group.ErrorMSG_HTML = {};

if (SERVER) then
	util.AddNetworkString( "CAP_ERROR" );
	util.AddNetworkString( "CL_CAP_ERROR" );
end

local ws_addonlist = {}

for _,v in pairs(engine.GetAddons()) do
	if (v.mounted) then
		ws_addonlist[tonumber(v.wsid)] = v.title;
	end
end

local oldfiles = {};

for k,v in pairs(file.Find("addons/carter_addon_pack_*.gma","GAME")) do
	table.insert(oldfiles,v);
end
for k,v in pairs(file.Find("addons/stargate_carter_addon_pack_175394472.gma","GAME")) do
	table.insert(oldfiles,v);
end

if (CLIENT) then

	local function CAP_ShowError(tbl)
		local text = "";
		for k,v in pairs(tbl) do
			if (k!=1) then
				text = text.."<br><br>";
			end
			if (type(v)=="table") then
				local adds = "";
				for t,a in pairs(v[2]) do
					if ((v[1]=="sg_err_09" or v[1]=="sg_err_04") and tonumber(t)) then -- AGP: 04 links the old pack to unsubscribe (a folder install has no link)
						adds = adds.."<br><a href='http://steamcommunity.com/sharedfiles/filedetails/?id="..t.."'>"..a:Replace("Carter Addon Pack:","CAP:").."</a>";
					else
						adds = adds.."<br>"..a;
					end
				end
				if (v[1]=="sg_err_13" and v[3]) then
					text = text.."<b>"..SGLanguage.GetMessage("sg_err_n").." #"..v[1]:gsub("[^0-9]","").."</b><br>"..SGLanguage.GetMessage(v[1],v[3],adds);
				else
					text = text.."<b>"..SGLanguage.GetMessage("sg_err_n").." #"..v[1]:gsub("[^0-9]","").."</b><br>"..SGLanguage.GetMessage(v[1],adds);
				end
			else
				text = text.."<b>"..SGLanguage.GetMessage("sg_err_n").." #"..v:gsub("[^0-9]","").."</b><br>"..SGLanguage.GetMessage(v);
			end
		end

		surface.PlaySound( "buttons/button2.wav" );

		StarGate.ShowCapMotd(SGLanguage.GetMessage("sg_err_title"),"<h2>"..SGLanguage.GetMessage("sg_err_html_t").."</h2>"..text)

	end

	net.Receive( "CAP_ERROR", function( length )
		local tbl = net.ReadTable();
		if (table.Count(tbl)==0) then return end
		CAP_ShowError(tbl);
	end)


end

local function logError(errorCode, errorMessage, htmlCode, extraInfo)
    if status ~= "Error" then
        status = "Error"
        MsgN("Status: "..status)
    end
    table.insert(StarGate_Group.ErrorMSG, {errorMessage, errorCode})
    table.insert(StarGate_Group.ErrorMSG_HTML, htmlCode)
    MsgN("-------")
    MsgN("Error #"..errorCode.."\n"..errorMessage:Replace("\\n","\n"))
end

-- an old CAP / CAP Enhanced code pack mounted next to this pack breaks both
-- (both packs use the same files and class names, so which version of a part runs is random)
local old = {}
for _, id in ipairs({3021712722, 175394472}) do
    if ws_addonlist[id] then old[id] = ws_addonlist[id] end
end
-- the same packs as plain folders in garrysmod/addons (GitHub / manual installs): any folder but ours that brings
-- CAP's own loader file
local me = string.match(debug.getinfo(1, "S").source or "", "addons/([^/]+)/lua/")
local _, dirs = file.Find("addons/*", "GAME")
for _, d in ipairs(dirs or {}) do
    if d ~= me and file.Exists("addons/" .. d .. "/lua/stargate/shared/capcheck.lua", "GAME") then
        old["folder " .. d] = "garrysmod/addons/" .. d
    end
end
if next(old) then
    logError("04", "An old CAP / CAP Enhanced code pack is installed alongside Ascension Gates. Ascension Gates already contains it, fixed.\\nBoth use the same files: please unsubscribe the old one and restart.", {"sg_err_04", old})
end

if #oldfiles > 0 then
    logError("13", "Old workshop files found, please remove it.", {"sg_err_13", oldfiles, "C:/Program Files (x86)/Steam/SteamApps/common/GarrysMod/garrysmod/addons"})
end

if not WireAddon and not file.Exists("weapons/gmod_tool/stools/wire_adv.lua", "LUA") then
    logError("07", "Wiremod cannot be found on your Garry's Mod Installation.\\nPlease make sure you've installed it correctly.", "sg_err_07")
end

if (status != "Error") then
	MsgN("Status: "..status)
else
	StarGate_Group.Error = true;
end
Msg("--------------------------\n")

if (SERVER) then
	net.Receive("CL_CAP_ERROR",function(len,ply)
		if (IsValid(ply) and ply:IsPlayer()) then
			local tbl = {net.ReadTable(),net.ReadTable()};
			StarGate_Group.ShowError(ply,tbl)
		end
	end)
end

function StarGate_Group.ShowError(ply,cl)
	local ErrorMSG = StarGate_Group.ErrorMSG;
	local ErrorMSG_HTML = StarGate_Group.ErrorMSG_HTML;
	if (cl!=nil) then
		ErrorMSG = cl[1];
		ErrorMSG_HTML = cl[2];
	end
	for k,v in pairs(ErrorMSG) do
		if (k==1) then
			MsgN("================================");
			MsgN("Ascension Gates Error:"); MsgN("-------");
			if (IsValid(ply)) then
				MsgN("Player: "..ply:Name());
				ply:SendLua( "MsgN(\"================================\")");
				ply:SendLua("MsgN(\"Ascension Gates Error:\")"); ply:SendLua("MsgN(\"-------\")");
			end
		else
			MsgN("-------");
			if (IsValid(ply)) then
				ply:SendLua("MsgN(\"-------\")");
			end
		end
		Msg("Error #"..v[2].."\n"..v[1]:Replace("\\n","\n").."\n");
		if (IsValid(ply)) then
			ply:SendLua("Msg(\"Error #"..v[2].."\\n"..v[1].."\\n\")");
		end
	end
	MsgN("================================");
	if (IsValid(ply)) then
		ply:SendLua("MsgN(\"================================\")");
		net.Start("CAP_ERROR");
		net.WriteTable(ErrorMSG_HTML);
		net.Send(ply);
	end
end

if (status == "Error") then
	MsgN("Ascension Gates: Loading error.");
end
