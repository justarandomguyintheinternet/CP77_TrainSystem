local config = require("modules/utils/config")

settings = {}

function settings.draw(ts)
    ts.CPS:setThemeBegin()
    ImGui.Begin("Train System Config", ImGuiWindowFlags.AlwaysAutoResize)

    if ts.observers.noSave then
        ImGui.PushStyleColor(ImGuiCol.Button, 0xff777777)
        ImGui.PushStyleColor(ImGuiCol.ButtonHovered, 0xff777777)
        ImGui.PushStyleColor(ImGuiCol.ButtonActive, 0xff777777)
        ImGui.Button("Train Speed Not Available Right Now")
        ImGui.PopStyleColor(3)
    else
        ts.settings.trainSpeed, changed = ImGui.InputInt("Train Speed", ts.settings.trainSpeed)
        if changed then config.saveFile("data/config.json", ts.settings) end
    end

    ts.settings.camDist, changed = ImGui.InputInt("Train TPP Cam Dist", ts.settings.camDist)
    ts.settings.camDist = math.min(math.max(ts.settings.camDist, 6), 22)
    if changed then config.saveFile("data/config.json", ts.settings) end

    ImGui.Separator()

    ImGui.Text("Default Seat:")

    if ImGui.RadioButton("Front Right", ts.settings.defaultSeat == 1) then
        ts.settings.defaultSeat = 1
        config.saveFile("data/config.json", ts.settings)
    end

    ImGui.SameLine()

    if ImGui.RadioButton("Back Right", ts.settings.defaultSeat == 2) then
        ts.settings.defaultSeat = 2
        config.saveFile("data/config.json", ts.settings)
    end

    ImGui.SameLine()

    if ImGui.RadioButton("Back Left", ts.settings.defaultSeat == 3) then
        ts.settings.defaultSeat = 3
        config.saveFile("data/config.json", ts.settings)
    end

    ImGui.SameLine()

    if ImGui.RadioButton("Front Left", ts.settings.defaultSeat == 4) then
        ts.settings.defaultSeat = 4
        config.saveFile("data/config.json", ts.settings)
    end

    ImGui.Separator()

    ts.settings.holdMult, changed = ImGui.InputFloat("Station Hold Time Multiplier", ts.settings.holdMult, 1, 1000, "%.2f")
    ts.settings.holdMult = math.min(math.max(ts.settings.holdMult, 0.2), 5)
    if changed then config.saveFile("data/config.json", ts.settings) end

    ts.settings.moneyPerStation, changed = ImGui.InputInt("Price per Station", ts.settings.moneyPerStation)
    if changed then config.saveFile("data/config.json", ts.settings) end

    ImGui.End()
    ts.CPS:setThemeEnd()
end

return settings