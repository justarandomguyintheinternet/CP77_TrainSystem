local config = require("modules/utils/config")

settings = {
    nativeOptions = {}
}

function settings.setupNative(ts)
    local nativeSettings = GetMod("nativeSettings")
    if not nativeSettings then
        print("[TrainSystem] Error: NativeSettings lib not found!")
        return
    end

    local cetVer = tonumber((GetVersion():gsub('^v(%d+)%.(%d+)%.(%d+)(.*)', function(major, minor, patch, wip) -- <-- This has been made by psiberx, all credits to him
        return ('%d.%02d%02d%d'):format(major, minor, patch, (wip == '' and 0 or 1))
    end)))

    if cetVer < 1.18001 then
        print("[TrainSystem] Error: CET version below recommended, switched to ImGui settings UI!")
        ts.settings.showImGui = true
        config.saveFile("data/config.json", ts.settings)
        return
    end

    nativeSettings.addTab("/trainSystem", "Train System")
    nativeSettings.addSubcategory("/trainSystem/train", "Train Settings")
    nativeSettings.addSubcategory("/trainSystem/station", "Station Settings")
    nativeSettings.addSubcategory("/trainSystem/misc", "Misc Settings")

    settings.nativeOptions["trainSpeed"] = nativeSettings.addRangeInt("/trainSystem/train", "Train Speed", "This controlls the speed of the train. Gets applied next time you take an elevator.", 1, 50, 1, ts.settings.trainSpeed, ts.defaultSettings.trainSpeed, function(value)
        ts.settings.trainSpeed = value
        config.saveFile("data/config.json", ts.settings)
    end)

    settings.nativeOptions["trainTPPDist"] = nativeSettings.addRangeInt("/trainSystem/train", "Train TPP Cam Distance", "This controlls the distance of the TPP camera. Gets applied next time you take an elevator.", 6, 30, 1, ts.settings.camDist, ts.defaultSettings.camDist, function(value)
        ts.settings.camDist = value
        config.saveFile("data/config.json", ts.settings)
    end)

    local list = {[1] = "Front Right", [2] = "Back Right", [3] = "Back Left", [4] = "Front Left"}
    settings.nativeOptions["trainSeat"] = nativeSettings.addSelectorString("/trainSystem/train", "Default FPP Seat", "Decides what seat the player is in by default, after switching to FPV", list, ts.settings.defaultSeat, ts.defaultSettings.defaultSeat, function(value)
        ts.settings.defaultSeat = value
        config.saveFile("data/config.json", ts.settings)
    end)

    settings.nativeOptions["trainTPPOnly"] = nativeSettings.addSwitch("/trainSystem/train", "TPP Cam only", "This disables the first person mode. Use it when you experience issues with FPV", ts.settings.tppOnly, ts.defaultSettings.tppOnly, function(state)
        ts.settings.tppOnly = state
        config.saveFile("data/config.json", ts.settings)
    end)

    settings.nativeOptions["stationHold"] = nativeSettings.addRangeFloat("/trainSystem/station", "Station Hold Time Multiplier", "Use this to in/decrease the time trains wait at stations", 0.05, 5, 0.05, "%.2f", ts.settings.holdMult, 1, function(value)
        ts.settings.holdMult = value
        config.saveFile("data/config.json", ts.settings)
    end)

    settings.nativeOptions["stationPrice"] = nativeSettings.addRangeInt("/trainSystem/station", "Money per station", "This controlls how much you have to pay per station travelled", 1, 50, 1, ts.settings.moneyPerStation, ts.defaultSettings.moneyPerStation, function(value)
        ts.settings.moneyPerStation = value
        config.saveFile("data/config.json", ts.settings)
    end)

    settings.nativeOptions["showImGui"] = nativeSettings.addSwitch("/trainSystem/misc", "Show ImGui settings UI", "Show all the settings here in a seperate ImGui window, visible when the CET overlay is opened. This option gets turned on when the CET version is too low for NativeSettings", ts.settings.showImGui, ts.defaultSettings.showImGui, function(state)
        ts.settings.showImGui = state
        config.saveFile("data/config.json", ts.settings)
    end)
end

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

    ts.settings.tppOnly, changed = ImGui.Checkbox("TPP Camera only", ts.settings.tppOnly)
    if changed then config.saveFile("data/config.json", ts.settings) end

    ImGui.End()
    ts.CPS:setThemeEnd()
end

return settings