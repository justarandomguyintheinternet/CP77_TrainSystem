local config = require("modules/utils/config")
local utils = require("modules/utils/utils")
local lang = require("modules/utils/lang")

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
    nativeSettings.addSubcategory("/trainSystem/train", lang.getText("settings_category_train"))
    nativeSettings.addSubcategory("/trainSystem/station", lang.getText("settings_category_station"))
    nativeSettings.addSubcategory("/trainSystem/misc", lang.getText("settings_category_misc"))

    settings.nativeOptions["trainSpeed"] = nativeSettings.addRangeInt("/trainSystem/train", lang.getText("settings_name_trainSpeed"), lang.getText("settings_description_trainSpeed"), 1, 50, 1, ts.settings.trainSpeed, ts.defaultSettings.trainSpeed, function(value)
        ts.settings.trainSpeed = value
        config.saveFile("data/config.json", ts.settings)
    end)

    settings.nativeOptions["trainTPPDist"] = nativeSettings.addRangeInt("/trainSystem/train", lang.getText("settings_name_trainTPPDist"), lang.getText("settings_description_trainTPPDist"), 6, 30, 1, ts.settings.camDist, ts.defaultSettings.camDist, function(value)
        ts.settings.camDist = value
        config.saveFile("data/config.json", ts.settings)
    end)

    local list = {[1] = "Front Right", [2] = "Back Right", [3] = "Back Left", [4] = "Front Left"}
    settings.nativeOptions["trainSeat"] = nativeSettings.addSelectorString("/trainSystem/train", lang.getText("settings_name_trainSeat"), lang.getText("settings_description_trainSeat"), list, ts.settings.defaultSeat, ts.defaultSettings.defaultSeat, function(value)
        ts.settings.defaultSeat = value
        config.saveFile("data/config.json", ts.settings)
    end)

    settings.nativeOptions["defaultFPP"] = nativeSettings.addSwitch("/trainSystem/train", lang.getText("settings_name_defaultFPP"), lang.getText("settings_description_defaultFPP"), ts.settings.defaultFPP, ts.defaultSettings.defaultFPP, function(state)
        ts.settings.defaultFPP = state
        config.saveFile("data/config.json", ts.settings)
    end)

    settings.nativeOptions["noHudTrain"] = nativeSettings.addSwitch("/trainSystem/train", lang.getText("settings_name_noHudTrain"), lang.getText("settings_description_noHudTrain"), ts.settings.noHudTrain, ts.defaultSettings.noHudTrain, function(state)
        ts.settings.noHudTrain = state
        config.saveFile("data/config.json", ts.settings)

        if ts.stationSys.activeTrain then
            if ts.stationSys.activeTrain.playerMounted then
                utils.toggleHUD(not state)
            end
        end
    end)

    settings.nativeOptions["autoCenter"] = nativeSettings.addSwitch("/trainSystem/train", lang.getText("settings_name_autoCenter"), lang.getText("settings_description_autoCenter"), ts.settings.autoCenter, ts.defaultSettings.autoCenter, function(state)
        ts.settings.autoCenter = state
        config.saveFile("data/config.json", ts.settings)
    end)

    settings.nativeOptions["blueTrain"] = nativeSettings.addSwitch("/trainSystem/train", lang.getText("settings_name_blueTrain"), lang.getText("settings_description_blueTrain"), ts.settings.blueTrain, ts.defaultSettings.blueTrain, function(state)
        ts.settings.blueTrain = state
        config.saveFile("data/config.json", ts.settings)
    end)

    settings.nativeOptions["stationHold"] = nativeSettings.addRangeFloat("/trainSystem/station", lang.getText("settings_name_stationHold"), lang.getText("settings_description_stationHold"), 0.05, 5, 0.05, "%.2f", ts.settings.holdMult, 1, function(value)
        ts.settings.holdMult = value
        config.saveFile("data/config.json", ts.settings)
    end)

    settings.nativeOptions["stationPrice"] = nativeSettings.addRangeInt("/trainSystem/station", lang.getText("settings_name_stationPrice"), lang.getText("settings_description_stationPrice"), 1, 50, 1, ts.settings.moneyPerStation, ts.defaultSettings.moneyPerStation, function(value)
        ts.settings.moneyPerStation = value
        config.saveFile("data/config.json", ts.settings)
    end)

    settings.nativeOptions["elevatorTime"] = nativeSettings.addRangeFloat("/trainSystem/station", lang.getText("settings_name_elevatorTime"), lang.getText("settings_description_elevatorTime"), 3, 15, 0.5, "%.2f", ts.settings.elevatorTime, ts.defaultSettings.elevatorTime, function(value)
        ts.settings.elevatorTime = value
        config.saveFile("data/config.json", ts.settings)
    end)

    local list = {[1] = "Vanilla", [2] = "Spicy's E3 HUD", [3] = "Superior UI"}
    settings.nativeOptions["uiLayout"] = nativeSettings.addSelectorString("/trainSystem/misc", lang.getText("settings_name_uiLayout"), lang.getText("settings_description_uiLayout"), list, ts.settings.uiLayout, ts.defaultSettings.uiLayout, function(value)
        ts.settings.uiLayout = value
        config.saveFile("data/config.json", ts.settings)
        if ts.observers.hudText then
            ts.observers.hudText:SetTintColor(utils.generateHUDColor(ts.settings.uiLayout))
        end
    end)

    settings.nativeOptions["unlockAllTracks"] = nativeSettings.addSwitch("/trainSystem/misc", lang.getText("settings_name_unlockAllTracks"), lang.getText("settings_description_unlockAllTracks"), ts.settings.unlockAllTracks, ts.defaultSettings.unlockAllTracks, function(state)
        ts.settings.unlockAllTracks = state
        ts.routingSystem:load()
        config.saveFile("data/config.json", ts.settings)
    end)

    settings.nativeOptions["elevatorGlitch"] = nativeSettings.addSwitch("/trainSystem/misc", lang.getText("settings_name_elevatorGlitch"), lang.getText("settings_description_elevatorGlitch"), ts.settings.elevatorGlitch, ts.defaultSettings.elevatorGlitch, function(state)
        ts.settings.elevatorGlitch = state
        config.saveFile("data/config.json", ts.settings)
    end)

    settings.nativeOptions["trainGlitch"] = nativeSettings.addSwitch("/trainSystem/misc", lang.getText("settings_name_trainGlitch"), lang.getText("settings_description_trainGlitch"), ts.settings.trainGlitch, ts.defaultSettings.trainGlitch, function(state)
        ts.settings.trainGlitch = state
        config.saveFile("data/config.json", ts.settings)
    end)

    settings.nativeOptions["showImGui"] = nativeSettings.addSwitch("/trainSystem/misc", lang.getText("settings_name_showImGui"), lang.getText("settings_description_showImGui"), ts.settings.showImGui, ts.defaultSettings.showImGui, function(state)
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
        ts.settings.trainSpeed, changed = ImGui.InputInt(lang.getText("settings_name_trainSpeed"), ts.settings.trainSpeed)
        if settings.nativeSettings then settings.nativeSettings.setOption(settings.nativeOptions["trainSpeed"], ts.settings.trainSpeed) end
        if changed then config.saveFile("data/config.json", ts.settings) end
    end

    ts.settings.camDist, changed = ImGui.InputInt(lang.getText("settings_name_trainTPPDist"), ts.settings.camDist)
    ts.settings.camDist = math.min(math.max(ts.settings.camDist, 6), 22)
    if changed then
        config.saveFile("data/config.json", ts.settings)
        if settings.nativeSettings then settings.nativeSettings.setOption(settings.nativeOptions["trainTPPDist"], ts.settings.camDist) end
    end

    ImGui.Text(lang.getText("settings_name_trainSeat") .. ":")

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

    ts.settings.defaultFPP, changed = ImGui.Checkbox(lang.getText("settings_name_defaultFPP"), ts.settings.defaultFPP)
    if changed then
        if settings.nativeSettings then settings.nativeSettings.setOption(settings.nativeOptions["defaultFPP"], ts.settings.defaultFPP) end
        config.saveFile("data/config.json", ts.settings)
    end

    ts.settings.noHudTrain, changed = ImGui.Checkbox(lang.getText("settings_name_noHudTrain"), ts.settings.noHudTrain)
    if changed then
        if settings.nativeSettings then settings.nativeSettings.setOption(settings.nativeOptions["noHudTrain"], ts.settings.noHudTrain) end
        config.saveFile("data/config.json", ts.settings)

        if ts.stationSys.activeTrain then
            if ts.stationSys.activeTrain.playerMounted then
                utils.toggleHUD(not ts.settings.noHudTrain)
            end
        end
    end

    ts.settings.autoCenter, changed = ImGui.Checkbox(lang.getText("settings_name_autoCenter"), ts.settings.autoCenter)
    if changed then
        if settings.nativeSettings then settings.nativeSettings.setOption(settings.nativeOptions["autoCenter"], ts.settings.autoCenter) end
        config.saveFile("data/config.json", ts.settings)
    end

    ts.settings.blueTrain, changed = ImGui.Checkbox(lang.getText("settings_name_blueTrain"), ts.settings.blueTrain)
    if changed then
        if settings.nativeSettings then settings.nativeSettings.setOption(settings.nativeOptions["blueTrain"], ts.settings.blueTrain) end
        config.saveFile("data/config.json", ts.settings)
    end

    ImGui.Separator()

    ts.settings.holdMult, changed = ImGui.InputFloat(lang.getText("settings_name_stationHold"), ts.settings.holdMult, 1, 1000, "%.2f")
    ts.settings.holdMult = math.min(math.max(ts.settings.holdMult, 0.2), 5)
    if changed then
        if settings.nativeSettings then settings.nativeSettings.setOption(settings.nativeOptions["stationHold"], ts.settings.holdMult) end
        config.saveFile("data/config.json", ts.settings)
    end

    ts.settings.moneyPerStation, changed = ImGui.InputInt(lang.getText("settings_name_stationPrice"), ts.settings.moneyPerStation)
    if changed then
        if settings.nativeSettings then settings.nativeSettings.setOption(settings.nativeOptions["stationPrice"], ts.settings.moneyPerStation) end
        config.saveFile("data/config.json", ts.settings)
    end

    ts.settings.elevatorTime, changed = ImGui.InputFloat(lang.getText("settings_name_elevatorTime"), ts.settings.elevatorTime, 3, 15, "%.1f")
    ts.settings.elevatorTime = math.min(math.max(ts.settings.elevatorTime, 3), 15)
    if changed then
        if settings.nativeSettings then settings.nativeSettings.setOption(settings.nativeOptions["elevatorTime"], ts.settings.elevatorTime) end
        config.saveFile("data/config.json", ts.settings)
    end

    ImGui.Separator()

    ImGui.Text(lang.getText("settings_name_uiLayout") .. ":")

    if ImGui.RadioButton("Vanilla", ts.settings.uiLayout == 1) then
        ts.settings.uiLayout = 1
        if settings.nativeSettings then settings.nativeSettings.setOption(settings.nativeOptions["uiLayout"], ts.settings.uiLayout) end
        config.saveFile("data/config.json", ts.settings)
        if ts.observers.hudText then
            ts.observers.hudText:SetTintColor(utils.generateHUDColor(ts.settings.uiLayout))
        end
    end

    ImGui.SameLine()

    if ImGui.RadioButton("Spicy's E3 HUD", ts.settings.uiLayout == 2) then
        ts.settings.uiLayout = 2
        if settings.nativeSettings then settings.nativeSettings.setOption(settings.nativeOptions["uiLayout"], ts.settings.uiLayout) end
        config.saveFile("data/config.json", ts.settings)
        if ts.observers.hudText then
            ts.observers.hudText:SetTintColor(utils.generateHUDColor(ts.settings.uiLayout))
        end
    end

    ImGui.SameLine()

    if ImGui.RadioButton("Superior UI", ts.settings.uiLayout == 3) then
        ts.settings.uiLayout = 3
        if settings.nativeSettings then settings.nativeSettings.setOption(settings.nativeOptions["uiLayout"], ts.settings.uiLayout) end
        config.saveFile("data/config.json", ts.settings)
        if ts.observers.hudText then
            ts.observers.hudText:SetTintColor(utils.generateHUDColor(ts.settings.uiLayout))
        end
    end

    ts.settings.unlockAllTracks, changed = ImGui.Checkbox(lang.getText("settings_name_unlockAllTracks"), ts.settings.unlockAllTracks)
    if changed then
        ts.routingSystem:load()
        if settings.nativeSettings then settings.nativeSettings.setOption(settings.nativeOptions["unlockAllTracks"], ts.settings.unlockAllTracks) end
        config.saveFile("data/config.json", ts.settings)
    end

    ts.settings.elevatorGlitch, changed = ImGui.Checkbox(lang.getText("settings_name_elevatorGlitch"), ts.settings.elevatorGlitch)
    if changed then
        if settings.nativeSettings then settings.nativeSettings.setOption(settings.nativeOptions["elevatorGlitch"], ts.settings.elevatorGlitch) end
        config.saveFile("data/config.json", ts.settings)
    end

    ts.settings.trainGlitch, changed = ImGui.Checkbox(lang.getText("settings_name_trainGlitch"), ts.settings.trainGlitch)
    if changed then
        if settings.nativeSettings then settings.nativeSettings.setOption(settings.nativeOptions["trainGlitch"], ts.settings.trainGlitch) end
        config.saveFile("data/config.json", ts.settings)
    end

    ImGui.End()
    ts.CPS:setThemeEnd()
end

return settings