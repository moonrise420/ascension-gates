if SERVER then
    AddCSLuaFile("vgui/cs_mw_main_menu.lua")

end

if CLIENT then
    include("vgui/cs_mw_main_menu.lua")

    net.Receive("mw_main_menu", function()


        local avCont = TDLib("DPanel") -- Parent is just a DFrame
        avCont:Stick(LEFT, 4) --Dock left, margin of 4 on all sides, invalidate parent
        :SquareFromHeight() --Sets the width to the height, making it a square
        :ClearPaint() -- Clears its background
        :Circle(Color(255, 0, 0, 255)) -- Draws a red circle as a background
        :SetSize(100,100)

        local av = TDLib("DPanel", avCont) --Creating our actual avatar
        av:Stick(LEFT, 2) -- Dock fill, margin of 2 on all sides
        av:CircleAvatar():SetPlayer(LocalPlayer(), 2) -- Make it a circle avatar and set the player to us

        local text = TDLib("DPanel", parent) --Panel for our dual text
        text:Stick(LEFT, 4) -- Dock fill, margin of 4 on all sides
        :ClearPaint() -- Clear its background
        :DualText(
        "Line one", -- Top line
        "Trebuchet24", -- Top line font
        Color(255, 255, 255, 255), -- Top line color

        "Line two", -- Bottom line
        "Trebuchet18", -- Bottom line font
        Color(200, 200, 200, 200), -- Bottom line color

        TEXT_ALIGN_LEFT --Making it align to the left horizontally
        )
        av:SetVisible(false)

        if (av:IsVisible()) then
            av:SetVisible(false)  
        else
            av:SetVisible(true)
        end
    end)


end