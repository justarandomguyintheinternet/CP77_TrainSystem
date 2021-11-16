local CPS = require("CPStyling")
local utils = require("modules/utils/utils")
local theme = CPS.theme

hud = {
    entryVisible = false,
    exitVisible = false,
    doorVisible = false,
    trainVisible = false,
    destVisible = false,

    interactionHUDTrain = false,
    interactionHUDExit = false,
    interactionHUDDoor = false,

    nextStationPoint = nil,
    nextStationText = ""
}

function hud.draw(ts)
    hud.drawTrain()
    hud.drawExit()
    hud.drawDoor()
    if hud.entryVisible then
        hud.drawEntry()
        hud.entryVisible = false
    end
    if hud.destVisible then
        hud.drawDestinations(ts.stationSys)
        hud.destVisible = false
    else
        observers.nextStationText = ""
        Game.GetMappinSystem():UnregisterMappin(observers.nextStationPoint)
        if ts.observers.hudText then
            ts.observers.hudText:SetVisible(false)
        end
    end
end

function hud.drawEntry(station)
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
    ImGui.Text("Enter Station")
    --ImGui.TextColored(1, 0.76, 0.23, 1, "[10 E$]")
    CPS.colorEnd()
    ImGui.End()
    CPS.colorEnd(1)
    CPS.styleEnd(1)
    CPS:setThemeEnd()
end

function hud.drawExit()
    if hud.exitVisible then
        hud.exitVisible = false
        utils.createInteractionHub("Exit Station", "Choice1", true)
        hud.interactionHUDExit = true
    else
        if hud.interactionHUDExit then
            utils.createInteractionHub("Exit Station", "Choice1", false)
        end
        hud.interactionHUDExit = false
    end
end

function hud.drawDoor()
    if hud.doorVisible then
        hud.doorVisible = false
        utils.createInteractionHub("Use Door", "Choice1", true) -- Spam it to make sure it really gets diplayed and not gets interrupted
        hud.interactionHUDDoor = true
    else
        if hud.interactionHUDDoor then
            utils.createInteractionHub("Use Door", "Choice1", false)
        end
        hud.interactionHUDDoor = false
    end
end

function hud.drawTrain()
    if hud.trainVisible then
        hud.trainVisible = false
        utils.createInteractionHub("Enter Train", "Choice1", true)
        hud.interactionHUDTrain = true
    else
        if hud.interactionHUDTrain then
            utils.createInteractionHub("Enter Train", "Choice1", false)
        end
        hud.interactionHUDTrain = false
    end
end

function hud.drawDestinations(sys)
    local text = "NCART Next Station:\n"

    for k, d in pairs(sys.pathsData) do
        if k == sys.currentPathsIndex then
            text = text .. tostring(" [X] " .. sys.stations[d.targetID].displayName .. "\n")

            if observers.nextStationText ~= sys.stations[d.targetID].displayName then
                Game.GetMappinSystem():UnregisterMappin(observers.nextStationPoint)
                observers.nextStationText = sys.stations[d.targetID].displayName
                observers.nextStationPoint = Game.GetMappinSystem():RegisterMappin(MappinData.new({ mappinType = 'Mappins.DefaultStaticMappin', variant = 'CustomPositionVariant', visibleThroughWalls = true }), sys.stations[d.targetID].trainExit.pos)
            end

        else
            text = text .. tostring(" [  ] " .. sys.stations[d.targetID].displayName .. "\n")
        end
    end

    if not sys.ts.observers.hudText then return end

    sys.ts.observers.hudText:SetVisible(true)
    sys.ts.observers.hudText:SetText(text)
end

return hud