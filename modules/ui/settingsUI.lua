local config = require("modules/utils/config")
local utils = require("modules/utils/utils")

settings = {
    nativeOptions = {},
    nativeSettings = nil
}

function settings.setupNative(ts)
    local nativeSettings = GetMod("nativeSettings")
    settings.nativeSettings = nativeSettings
    if not nativeSettings then
        print("[MetroSystem] Error: NativeSettings lib not found, switching to ImGui UI!")
        ts.settings.showImGui = true
        config.saveFile("data/config.json", ts.settings)
        return
    end

    local cetVer = tonumber((GetVersion():gsub('^v(%d+)%.(%d+)%.(%d+)(.*)', function(major, minor, patch, wip) -- <-- This has been made by psiberx, all credits to him
        return ('%d.%02d%02d%d'):format(major, minor, patch, (wip == '' and 0 or 1))
    end)))

    if cetVer < 1.18 then
        print("[MetroSystem] Error: CET version below recommended, switched to ImGui settings UI!")
        ts.settings.showImGui = true
        config.saveFile("data/config.json", ts.settings)
        return
    end

    nativeSettings.addTab("/trainSystem", "Metro")
    nativeSettings.addSubcategory("/trainSystem/train", "Train Settings")
    nativeSettings.addSubcategory("/trainSystem/station", "Station Settings")
    nativeSettings.addSubcategory("/trainSystem/misc", "Misc Settings")

    settings.nativeOptions["trainSpeed"] = nativeSettings.addRangeInt("/trainSystem/train", "Train Speed", "This controlls the speed of the train. Gets applied next time you enter / leave a station", 1, 50, 1, ts.settings.trainSpeed, ts.defaultSettings.trainSpeed, function(value)
        ts.settings.trainSpeed = value
        config.saveFile("data/config.json", ts.settings)
    end)

    settings.nativeOptions["trainTPPDist"] = nativeSettings.addRangeInt("/trainSystem/train", "Train TPP Cam Distance", "This controlls the distance of the TPP camera. Gets applied next time you enter / leave a station", 6, 30, 1, ts.settings.camDist, ts.defaultSettings.camDist, function(value)
        ts.settings.camDist = value
        config.saveFile("data/config.json", ts.settings)
    end)

    local list = {[1] = "Front Right", [2] = "Back Right", [3] = "Back Left", [4] = "Front Left"}
    settings.nativeOptions["trainSeat"] = nativeSettings.addSelectorString("/trainSystem/train", "Default FPP Seat", "Decides what seat the player is in by default, after switching to FPV", list, ts.settings.defaultSeat, ts.defaultSettings.defaultSeat, function(value)
        ts.settings.defaultSeat = value
        config.saveFile("data/config.json", ts.settings)
    end)

    settings.nativeOptions["noHudTrain"] = nativeSettings.addSwitch("/trainSystem/train", "Hide HUD when in train", "This option hides the entire HUD when mounted to the train", ts.settings.noHudTrain, ts.defaultSettings.noHudTrain, function(state)
        ts.settings.noHudTrain = state
        config.saveFile("data/config.json", ts.settings)

        if ts.stationSys.activeTrain then
            if ts.stationSys.activeTrain.playerMounted then
                utils.toggleHUD(not state)
            end
        end
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

    settings.nativeOptions["elevatorTime"] = nativeSettings.addRangeFloat("/trainSystem/station", "Elevator Duration", "This controlls how long the elevator ride takes, in seconds", 3, 15, 0.5, "%.2f", ts.settings.elevatorTime, ts.defaultSettings.elevatorTime, function(value)
        ts.settings.elevatorTime = value
        config.saveFile("data/config.json", ts.settings)
    end)

    local list = {[1] = "Vanilla", [2] = "Spicy's E3 HUD", [3] = "Superior UI"}
    settings.nativeOptions["uiLayout"] = nativeSettings.addSelectorString("/trainSystem/misc", "HUD Mod Fix", "If you are using the E3 HUD mod or the Superior UI mod, select them here, to make sure the \"Next Station\" text gets properly positioned and colored", list, ts.settings.uiLayout, ts.defaultSettings.uiLayout, function(value)
        ts.settings.uiLayout = value
        config.saveFile("data/config.json", ts.settings)
        if ts.observers.hudText then
            ts.observers.hudText:SetMargin(utils.generateHUDMargin(ts.settings.uiLayout))
            ts.observers.hudText:SetTintColor(utils.generateHUDColor(ts.settings.uiLayout))
        end
    end)

    settings.nativeOptions["tppOffset"] = nativeSettings.addRangeFloat("/trainSystem/misc", "TPP Player Offset", "For the very rare case that the players head sticks out during TPP mode, lower this value to lower the players position", 1, 2, 0.1, "%.1f", ts.settings.tppOffset, ts.defaultSettings.tppOffset, function(value)
        ts.settings.tppOffset = value
        config.saveFile("data/config.json", ts.settings)
    end)

    settings.nativeOptions["showImGui"] = nativeSettings.addSwitch("/trainSystem/misc", "Show ImGui settings UI", "Show all the settings here in a seperate ImGui window, visible when the CET overlay is opened. This option gets turned on when the CET version is too low for NativeSettings", ts.settings.showImGui, ts.defaultSettings.showImGui, function(state)
        ts.settings.showImGui = state
        config.saveFile("data/config.json", ts.settings)
    end)
end

function settings.draw(ts) -- Draw alternative ImGui window
    ts.CPS:setThemeBegin()
    ImGui.Begin("Metro System Config", ImGuiWindowFlags.AlwaysAutoResize)

    if ts.observers.noSave then
        ImGui.PushStyleColor(ImGuiCol.Button, 0xff777777)
        ImGui.PushStyleColor(ImGuiCol.ButtonHovered, 0xff777777)
        ImGui.PushStyleColor(ImGuiCol.ButtonActive, 0xff777777)
        ImGui.Button("Train Speed Not Available Right Now")
        ImGui.PopStyleColor(3)
    else
        ts.settings.trainSpeed, changed = ImGui.InputInt("Train Speed", ts.settings.trainSpeed)
        if settings.nativeSettings then settings.nativeSettings.setOption(settings.nativeOptions["trainSpeed"], ts.settings.trainSpeed) end
        if changed then config.saveFile("data/config.json", ts.settings) end
    end

    ts.settings.camDist, changed = ImGui.InputInt("Train TPP Cam Dist", ts.settings.camDist)
    ts.settings.camDist = math.min(math.max(ts.settings.camDist, 6), 22)
    if changed then
        config.saveFile("data/config.json", ts.settings)
        if settings.nativeSettings then settings.nativeSettings.setOption(settings.nativeOptions["trainTPPDist"], ts.settings.camDist) end
    end

    ImGui.Text("Default Seat:")

    if ImGui.RadioButton("Front Right", ts.settings.defaultSeat == 1) then
        ts.settings.defaultSeat = 1
        if settings.nativeSettings then settings.nativeSettings.setOption(settings.nativeOptions["trainSeat"], ts.settings.defaultSeat) end
        config.saveFile("data/config.json", ts.settings)
    end

    ImGui.SameLine()

    if ImGui.RadioButton("Back Right", ts.settings.defaultSeat == 2) then
        ts.settings.defaultSeat = 2
        if settings.nativeSettings then settings.nativeSettings.setOption(settings.nativeOptions["trainSeat"], ts.settings.defaultSeat) end
        config.saveFile("data/config.json", ts.settings)
    end

    ImGui.SameLine()

    if ImGui.RadioButton("Back Left", ts.settings.defaultSeat == 3) then
        ts.settings.defaultSeat = 3
        if settings.nativeSettings then settings.nativeSettings.setOption(settings.nativeOptions["trainSeat"], ts.settings.defaultSeat) end
        config.saveFile("data/config.json", ts.settings)
    end

    ImGui.SameLine()

    if ImGui.RadioButton("Front Left", ts.settings.defaultSeat == 4) then
        ts.settings.defaultSeat = 4
        if settings.nativeSettings then settings.nativeSettings.setOption(settings.nativeOptions["trainSeat"], ts.settings.defaultSeat) end
        config.saveFile("data/config.json", ts.settings)
    end

    ts.settings.noHudTrain, changed = ImGui.Checkbox("Hide HUD when in train", ts.settings.noHudTrain)
    if changed then
        if settings.nativeSettings then settings.nativeSettings.setOption(settings.nativeOptions["noHudTrain"], ts.settings.noHudTrain) end
        config.saveFile("data/config.json", ts.settings)

        if ts.stationSys.activeTrain then
            if ts.stationSys.activeTrain.playerMounted then
                utils.toggleHUD(not ts.settings.noHudTrain)
            end
        end
    end

    ts.settings.tppOnly, changed = ImGui.Checkbox("TPP Camera only", ts.settings.tppOnly)
    if changed then
        if settings.nativeSettings then settings.nativeSettings.setOption(settings.nativeOptions["trainTPPOnly"], ts.settings.tppOnly) end
        config.saveFile("data/config.json", ts.settings)
    end

    ImGui.Separator()

    ts.settings.holdMult, changed = ImGui.InputFloat("Station Hold Time Multiplier", ts.settings.holdMult, 1, 1000, "%.2f")
    ts.settings.holdMult = math.min(math.max(ts.settings.holdMult, 0.2), 5)
    if changed then
        if settings.nativeSettings then settings.nativeSettings.setOption(settings.nativeOptions["stationHold"], ts.settings.holdMult) end
        config.saveFile("data/config.json", ts.settings)
    end

    ts.settings.moneyPerStation, changed = ImGui.InputInt("Price per Station", ts.settings.moneyPerStation)
    if changed then
        if settings.nativeSettings then settings.nativeSettings.setOption(settings.nativeOptions["stationPrice"], ts.settings.moneyPerStation) end
        config.saveFile("data/config.json", ts.settings)
    end

    ts.settings.elevatorTime, changed = ImGui.InputFloat("Elevator duration", ts.settings.elevatorTime, 3, 15, "%.1f")
    ts.settings.elevatorTime = math.min(math.max(ts.settings.elevatorTime, 3), 15)
    if changed then
        if settings.nativeSettings then settings.nativeSettings.setOption(settings.nativeOptions["elevatorTime"], ts.settings.elevatorTime) end
        config.saveFile("data/config.json", ts.settings)
    end

    ImGui.Separator()

    ts.settings.tppOffset, changed = ImGui.InputFloat("TPP Player height offset", ts.settings.tppOffset, 1, 2, "%.1f")
    ts.settings.tppOffset = math.min(math.max(ts.settings.tppOffset, 1), 2)
    if changed then
        if settings.nativeSettings then settings.nativeSettings.setOption(settings.nativeOptions["tppOffset"], ts.settings.tppOffset) end
        config.saveFile("data/config.json", ts.settings)
    end

    ImGui.Text("HUD Mod Fix:")

    if ImGui.RadioButton("Vanilla", ts.settings.uiLayout == 1) then
        ts.settings.uiLayout = 1
        if settings.nativeSettings then settings.nativeSettings.setOption(settings.nativeOptions["uiLayout"], ts.settings.uiLayout) end
        config.saveFile("data/config.json", ts.settings)
        if ts.observers.hudText then
            ts.observers.hudText:SetMargin(utils.generateHUDMargin(ts.settings.uiLayout))
            ts.observers.hudText:SetTintColor(utils.generateHUDColor(ts.settings.uiLayout))
        end
    end

    ImGui.SameLine()

    if ImGui.RadioButton("Spicy's E3 HUD", ts.settings.uiLayout == 2) then
        ts.settings.uiLayout = 2
        if settings.nativeSettings then settings.nativeSettings.setOption(settings.nativeOptions["uiLayout"], ts.settings.uiLayout) end
        config.saveFile("data/config.json", ts.settings)
        if ts.observers.hudText then
            ts.observers.hudText:SetMargin(utils.generateHUDMargin(ts.settings.uiLayout))
            ts.observers.hudText:SetTintColor(utils.generateHUDColor(ts.settings.uiLayout))
        end
    end

    ImGui.SameLine()

    if ImGui.RadioButton("Superior UI", ts.settings.uiLayout == 3) then
        ts.settings.uiLayout = 3
        if settings.nativeSettings then settings.nativeSettings.setOption(settings.nativeOptions["uiLayout"], ts.settings.uiLayout) end
        config.saveFile("data/config.json", ts.settings)
        if ts.observers.hudText then
            ts.observers.hudText:SetMargin(utils.generateHUDMargin(ts.settings.uiLayout))
            ts.observers.hudText:SetTintColor(utils.generateHUDColor(ts.settings.uiLayout))
        end
    end

    ImGui.End()
    ts.CPS:setThemeEnd()
end

return settings