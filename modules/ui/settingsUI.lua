local config = require("modules/utils/config")
local utils = require("modules/utils/utils")
local I18N = require("modules/utils/I18N")

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

    nativeSettings.addTab("/trainSystem", I18N.OnScreen("ns_tab_name"))
    nativeSettings.addSubcategory("/trainSystem/train", I18N.OnScreen("ns_category_train"))
    nativeSettings.addSubcategory("/trainSystem/station", I18N.OnScreen("ns_category_station"))
    nativeSettings.addSubcategory("/trainSystem/misc", I18N.OnScreen("ns_category_misc"))

    settings.nativeOptions["trainSpeed"] = nativeSettings.addRangeInt("/trainSystem/train", I18N.OnScreen("no_train_speed_title"),I18N.OnScreen("no_train_speed_desc"), 1, 50, 1, ts.settings.trainSpeed, ts.defaultSettings.trainSpeed, function(value)
        ts.settings.trainSpeed = value
        config.saveFile("data/config.json", ts.settings)
    end)

    settings.nativeOptions["trainTPPDist"] = nativeSettings.addRangeInt("/trainSystem/train", I18N.OnScreen("no_train_tppcam_title"),I18N.OnScreen("no_train_tppcam_desc"), 6, 30, 1, ts.settings.camDist, ts.defaultSettings.camDist, function(value)
        ts.settings.camDist = value
        config.saveFile("data/config.json", ts.settings)
    end)

    local list = {[1] = I18N.OnScreen("no_train_fppview_op1"), [2] = I18N.OnScreen("no_train_fppview_op2"), [3] = I18N.OnScreen("no_train_fppview_op3"), [4] = I18N.OnScreen("no_train_fppview_op4")}
    settings.nativeOptions["trainSeat"] = nativeSettings.addSelectorString("/trainSystem/train", I18N.OnScreen("no_train_fppview_title"),I18N.OnScreen("no_train_fppview_desc"), list, ts.settings.defaultSeat, ts.defaultSettings.defaultSeat, function(value)
        ts.settings.defaultSeat = value
        config.saveFile("data/config.json", ts.settings)
    end)

    settings.nativeOptions["noHudTrain"] = nativeSettings.addSwitch("/trainSystem/train", I18N.OnScreen("no_train_hidehud_title"),I18N.OnScreen("no_train_hidehud_desc"), ts.settings.noHudTrain, ts.defaultSettings.noHudTrain, function(state)
        ts.settings.noHudTrain = state
        config.saveFile("data/config.json", ts.settings)

        if ts.stationSys.activeTrain then
            if ts.stationSys.activeTrain.playerMounted then
                utils.toggleHUD(not state)
            end
        end
    end)

    settings.nativeOptions["trainTPPOnly"] = nativeSettings.addSwitch("/trainSystem/train", I18N.OnScreen("no_train_tpponly_title"),I18N.OnScreen("no_train_tpponly_desc"), ts.settings.tppOnly, ts.defaultSettings.tppOnly, function(state)
        ts.settings.tppOnly = state
        config.saveFile("data/config.json", ts.settings)
    end)

    settings.nativeOptions["stationHold"] = nativeSettings.addRangeFloat("/trainSystem/station", I18N.OnScreen("no_station_hold_title"),I18N.OnScreen("no_station_hold_desc"), 0.05, 5, 0.05, "%.2f", ts.settings.holdMult, 1, function(value)
        ts.settings.holdMult = value
        config.saveFile("data/config.json", ts.settings)
    end)

    settings.nativeOptions["stationPrice"] = nativeSettings.addRangeInt("/trainSystem/station", I18N.OnScreen("no_station_money_title"),I18N.OnScreen("no_station_money_desc"), 1, 50, 1, ts.settings.moneyPerStation, ts.defaultSettings.moneyPerStation, function(value)
        ts.settings.moneyPerStation = value
        config.saveFile("data/config.json", ts.settings)
    end)

    settings.nativeOptions["elevatorTime"] = nativeSettings.addRangeFloat("/trainSystem/station", I18N.OnScreen("no_station_elevator_time_title"),I18N.OnScreen("no_station_elevator_time_desc"), 3, 15, 0.5, "%.2f", ts.settings.elevatorTime, ts.defaultSettings.elevatorTime, function(value)
        ts.settings.elevatorTime = value
        config.saveFile("data/config.json", ts.settings)
    end)

    local list = {[1] = "Vanilla", [2] = "Spicy's E3 HUD", [3] = "Superior UI"}
    settings.nativeOptions["uiLayout"] = nativeSettings.addSelectorString("/trainSystem/misc", I18N.OnScreen("no_misc_hudfix_title"),I18N.OnScreen("no_misc_hudfix_desc"), list, ts.settings.uiLayout, ts.defaultSettings.uiLayout, function(value)
        ts.settings.uiLayout = value
        config.saveFile("data/config.json", ts.settings)
        if ts.observers.hudText then
            ts.observers.hudText:SetMargin(utils.generateHUDMargin(ts.settings.uiLayout))
            ts.observers.hudText:SetTintColor(utils.generateHUDColor(ts.settings.uiLayout))
        end
    end)

    settings.nativeOptions["unlockAllTracks"] = nativeSettings.addSwitch("/trainSystem/misc", I18N.OnScreen("no_misc_unlockall_title"),I18N.OnScreen("no_misc_unlockall_desc"), ts.settings.unlockAllTracks, ts.defaultSettings.unlockAllTracks, function(state)
        ts.settings.unlockAllTracks = state
        ts.trackSys:load()
        config.saveFile("data/config.json", ts.settings)
    end)

    settings.nativeOptions["elevatorGlitch"] = nativeSettings.addSwitch("/trainSystem/misc", I18N.OnScreen("no_misc_elevator_glitch_title"),I18N.OnScreen("no_misc_elevator_glitch_desc"), ts.settings.elevatorGlitch, ts.defaultSettings.elevatorGlitch, function(state)
        ts.settings.elevatorGlitch = state
        config.saveFile("data/config.json", ts.settings)
    end)

    settings.nativeOptions["trainGlitch"] = nativeSettings.addSwitch("/trainSystem/misc", I18N.OnScreen("no_misc_train_glitch_title"),I18N.OnScreen("no_misc_train_glitch_desc"), ts.settings.trainGlitch, ts.defaultSettings.trainGlitch, function(state)
        ts.settings.trainGlitch = state
        config.saveFile("data/config.json", ts.settings)
    end)

    settings.nativeOptions["tppOffset"] = nativeSettings.addRangeFloat("/trainSystem/misc", I18N.OnScreen("no_misc_tpp_offset_title"),I18N.OnScreen("no_misc_tpp_offset_desc"), 1, 2, 0.1, "%.1f", ts.settings.tppOffset, ts.defaultSettings.tppOffset, function(value)
        ts.settings.tppOffset = value
        config.saveFile("data/config.json", ts.settings)
    end)

    settings.nativeOptions["showImGui"] = nativeSettings.addSwitch("/trainSystem/misc", I18N.OnScreen("no_misc_imgui_set_title"),I18N.OnScreen("no_misc_imgui_set_desc"), ts.settings.showImGui, ts.defaultSettings.showImGui, function(state)
        ts.settings.showImGui = state
        config.saveFile("data/config.json", ts.settings)
    end)
end

function settings.draw(ts) -- Draw alternative ImGui window
    ts.CPS:setThemeBegin()
    ImGui.Begin(I18N.OnScreen("imgui_metro_system"), ImGuiWindowFlags.AlwaysAutoResize)

    if ts.observers.noSave then
        ImGui.PushStyleColor(ImGuiCol.Button, 0xff777777)
        ImGui.PushStyleColor(ImGuiCol.ButtonHovered, 0xff777777)
        ImGui.PushStyleColor(ImGuiCol.ButtonActive, 0xff777777)
        ImGui.Button(I18N.OnScreen("imgui_train_speed_button"))
        ImGui.PopStyleColor(3)
    else
        ts.settings.trainSpeed, changed = ImGui.InputInt(I18N.OnScreen("no_train_speed_title"), ts.settings.trainSpeed)
        if settings.nativeSettings then settings.nativeSettings.setOption(settings.nativeOptions["trainSpeed"], ts.settings.trainSpeed) end
        if changed then config.saveFile("data/config.json", ts.settings) end
    end

    ts.settings.camDist, changed = ImGui.InputInt(I18N.OnScreen("no_train_tppcam_title"), ts.settings.camDist)
    ts.settings.camDist = math.min(math.max(ts.settings.camDist, 6), 22)
    if changed then
        config.saveFile("data/config.json", ts.settings)
        if settings.nativeSettings then settings.nativeSettings.setOption(settings.nativeOptions["trainTPPDist"], ts.settings.camDist) end
    end

    ImGui.Text("Default Seat:")

    if ImGui.RadioButton(I18N.OnScreen("no_train_fppview_op1"), ts.settings.defaultSeat == 1) then
        ts.settings.defaultSeat = 1
        if settings.nativeSettings then settings.nativeSettings.setOption(settings.nativeOptions["trainSeat"], ts.settings.defaultSeat) end
        config.saveFile("data/config.json", ts.settings)
    end

    ImGui.SameLine()

    if ImGui.RadioButton(I18N.OnScreen("no_train_fppview_op2"), ts.settings.defaultSeat == 2) then
        ts.settings.defaultSeat = 2
        if settings.nativeSettings then settings.nativeSettings.setOption(settings.nativeOptions["trainSeat"], ts.settings.defaultSeat) end
        config.saveFile("data/config.json", ts.settings)
    end

    ImGui.SameLine()

    if ImGui.RadioButton(I18N.OnScreen("no_train_fppview_op3"), ts.settings.defaultSeat == 3) then
        ts.settings.defaultSeat = 3
        if settings.nativeSettings then settings.nativeSettings.setOption(settings.nativeOptions["trainSeat"], ts.settings.defaultSeat) end
        config.saveFile("data/config.json", ts.settings)
    end

    ImGui.SameLine()

    if ImGui.RadioButton(I18N.OnScreen("no_train_fppview_op4"), ts.settings.defaultSeat == 4) then
        ts.settings.defaultSeat = 4
        if settings.nativeSettings then settings.nativeSettings.setOption(settings.nativeOptions["trainSeat"], ts.settings.defaultSeat) end
        config.saveFile("data/config.json", ts.settings)
    end

    ts.settings.noHudTrain, changed = ImGui.Checkbox(I18N.OnScreen("no_train_hidehud_title"), ts.settings.noHudTrain)
    if changed then
        if settings.nativeSettings then settings.nativeSettings.setOption(settings.nativeOptions["noHudTrain"], ts.settings.noHudTrain) end
        config.saveFile("data/config.json", ts.settings)

        if ts.stationSys.activeTrain then
            if ts.stationSys.activeTrain.playerMounted then
                utils.toggleHUD(not ts.settings.noHudTrain)
            end
        end
    end

    ts.settings.tppOnly, changed = ImGui.Checkbox(I18N.OnScreen("no_train_tpponly_title"), ts.settings.tppOnly)
    if changed then
        if settings.nativeSettings then settings.nativeSettings.setOption(settings.nativeOptions["trainTPPOnly"], ts.settings.tppOnly) end
        config.saveFile("data/config.json", ts.settings)
    end

    ImGui.Separator()

    ts.settings.holdMult, changed = ImGui.InputFloat(I18N.OnScreen("no_station_hold_title"), ts.settings.holdMult, 1, 1000, "%.2f")
    ts.settings.holdMult = math.min(math.max(ts.settings.holdMult, 0.2), 5)
    if changed then
        if settings.nativeSettings then settings.nativeSettings.setOption(settings.nativeOptions["stationHold"], ts.settings.holdMult) end
        config.saveFile("data/config.json", ts.settings)
    end

    ts.settings.moneyPerStation, changed = ImGui.InputInt(I18N.OnScreen("no_station_money_title"), ts.settings.moneyPerStation)
    if changed then
        if settings.nativeSettings then settings.nativeSettings.setOption(settings.nativeOptions["stationPrice"], ts.settings.moneyPerStation) end
        config.saveFile("data/config.json", ts.settings)
    end

    ts.settings.elevatorTime, changed = ImGui.InputFloat(I18N.OnScreen("no_station_elevator_time_title"), ts.settings.elevatorTime, 3, 15, "%.1f")
    ts.settings.elevatorTime = math.min(math.max(ts.settings.elevatorTime, 3), 15)
    if changed then
        if settings.nativeSettings then settings.nativeSettings.setOption(settings.nativeOptions["elevatorTime"], ts.settings.elevatorTime) end
        config.saveFile("data/config.json", ts.settings)
    end

    ImGui.Separator()

    ts.settings.tppOffset, changed = ImGui.InputFloat(I18N.OnScreen("no_misc_tpp_offset_title"), ts.settings.tppOffset, 1, 2, "%.1f")
    ts.settings.tppOffset = math.min(math.max(ts.settings.tppOffset, 1), 2)
    if changed then
        if settings.nativeSettings then settings.nativeSettings.setOption(settings.nativeOptions["tppOffset"], ts.settings.tppOffset) end
        config.saveFile("data/config.json", ts.settings)
    end

    ImGui.Text(I18N.OnScreen("no_misc_hudfix_title")..":")

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

    ts.settings.unlockAllTracks, changed = ImGui.Checkbox(I18N.OnScreen("no_misc_unlockall_title"), ts.settings.unlockAllTracks)
    if changed then
        ts.trackSys:load()
        if settings.nativeSettings then settings.nativeSettings.setOption(settings.nativeOptions["unlockAllTracks"], ts.settings.unlockAllTracks) end
        config.saveFile("data/config.json", ts.settings)
    end

    ts.settings.elevatorGlitch, changed = ImGui.Checkbox(I18N.OnScreen("no_misc_elevator_glitch_msg"), ts.settings.elevatorGlitch)
    if changed then
        if settings.nativeSettings then settings.nativeSettings.setOption(settings.nativeOptions["elevatorGlitch"], ts.settings.elevatorGlitch) end
        config.saveFile("data/config.json", ts.settings)
    end

    ts.settings.trainGlitch, changed = ImGui.Checkbox(I18N.OnScreen("no_misc_train_glitch_msg"), ts.settings.trainGlitch)
    if changed then
        if settings.nativeSettings then settings.nativeSettings.setOption(settings.nativeOptions["trainGlitch"], ts.settings.trainGlitch) end
        config.saveFile("data/config.json", ts.settings)
    end

    ImGui.End()
    ts.CPS:setThemeEnd()
end

return settings