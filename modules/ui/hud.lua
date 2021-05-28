local CPS = require("CPStyling")

hud = {}

function hud.drawEntry(station)
    CPS:setThemeBegin()
    CPS.styleBegin("WindowBorderSize", 0)
    CPS.colorBegin("WindowBg", {0,0,0,0})
    ImGui.Begin("ts_hud_entry", bit32.bor(ImGuiWindowFlags.AlwaysAutoResize, ImGuiWindowFlags.NoTitleBar))

    ImGui.Text("Enter " .. station.displayName .. " Metro Station")

    ImGui.End()
    CPS.colorEnd(1)
    CPS.styleEnd(1)
    CPS:setThemeEnd()
end

function hud.drawExit()
    CPS:setThemeBegin()
    CPS.styleBegin("WindowBorderSize", 0)
    CPS.colorBegin("WindowBg", {0,0,0,0})
    ImGui.Begin("ts_hud:exit", bit32.bor(ImGuiWindowFlags.AlwaysAutoResize, ImGuiWindowFlags.NoTitleBar))

    ImGui.Text("Exit Station")

    ImGui.End()
    CPS.colorEnd(1)
    CPS.styleEnd(1)
    CPS:setThemeEnd()
end

function hud.drawDestinations(sys)
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