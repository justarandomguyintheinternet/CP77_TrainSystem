local CPS = require("CPStyling")
local theme = CPS.theme

hud = {}

function hud.drawEntry(station)
    local wWidth, wHeight = GetDisplayResolution()

    CPS:setThemeBegin()
    CPS.styleBegin("WindowBorderSize", 0)
    CPS.colorBegin("WindowBg", {0,0,0,0})
    ImGui.Begin("enterStation", true, bit32.bor(ImGuiWindowFlags.NoResize and ImGuiWindowFlags.AlwaysAutoResize and ImGuiWindowFlags.NoTitleBar))
    ImGui.SetWindowFontScale(1.5)
    ImGui.SetWindowPos((wWidth / 2) - 5, wHeight * 0.84)
    ImGui.TextColored(1, 0.76, 0.23, 1, "[15 E$]")
    ImGui.End()
    CPS.colorEnd(1)
    CPS.styleEnd(1)
    CPS:setThemeEnd()
end

function hud.drawExit()
    local wWidth, wHeight = GetDisplayResolution()

    CPS:setThemeBegin()
    CPS.styleBegin("WindowBorderSize", 0)
    CPS.colorBegin("WindowBg", {0,0,0,0})
    ImGui.Begin("exitStation", true, bit32.bor(ImGuiWindowFlags.NoResize and ImGuiWindowFlags.AlwaysAutoResize and ImGuiWindowFlags.NoTitleBar))
    ImGui.SetWindowFontScale(1.5)
    ImGui.SetWindowPos((wWidth / 2) - 100, wHeight * 0.79)
    CPS.colorBegin("Text", theme.CPButtonText)
    CPS.CPRect("F", 28, 28, theme.Hidden, theme.CPButtonText, 1, 2)
    ImGui.SameLine()
    ImGui.Text("Exit Station")
    --ImGui.TextColored(1, 0.76, 0.23, 1, "[10 E$]")
    CPS.colorEnd()
    ImGui.End()
    CPS.colorEnd(1)
    CPS.styleEnd(1)
    CPS:setThemeEnd()
end

function hud.enterTrain()
    local wWidth, wHeight = GetDisplayResolution()

    CPS:setThemeBegin()
    CPS.styleBegin("WindowBorderSize", 0)
    CPS.colorBegin("WindowBg", {0,0,0,0})
    ImGui.Begin("enter train", true, bit32.bor(ImGuiWindowFlags.NoResize and ImGuiWindowFlags.AlwaysAutoResize and ImGuiWindowFlags.NoTitleBar))
    ImGui.SetWindowFontScale(1.5)
    ImGui.SetWindowPos((wWidth / 2) - 100, wHeight * 0.78)
    CPS.colorBegin("Text", theme.CPButtonText)
    CPS.CPRect("F", 28, 28, theme.Hidden, theme.CPButtonText, 1, 2)
    ImGui.SameLine()
    ImGui.Text("Enter Train")
    --ImGui.TextColored(1, 0.76, 0.23, 1, "[10 E$]")
    CPS.colorEnd()
    ImGui.End()
    CPS.colorEnd(1)
    CPS.styleEnd(1)
    CPS:setThemeEnd()
end

function hud.drawDestinations(sys)
    local wWidth, wHeight = GetDisplayResolution()

    CPS:setThemeBegin()
    CPS.styleBegin("WindowBorderSize", 0)
    CPS.colorBegin("WindowBg", {0,0,0,0})
    ImGui.Begin("ts_hud_destinations", bit32.bor(ImGuiWindowFlags.AlwaysAutoResize, ImGuiWindowFlags.NoTitleBar))

    for k, d in pairs(sys.pathsData) do
        if k == sys.currentPathsIndex then
            ImGui.Text(sys.stations[d.targetID].displayName .. " X")
        else
            ImGui.Text(sys.stations[d.targetID].displayName)
        end
    end

    ImGui.End()
    CPS.colorEnd(1)
    CPS.styleEnd(1)
    CPS:setThemeEnd()
end

return hud