local CPS = require("CPStyling")
local utils = require("modules/utils/utils")
local I18N = require("modules/utils/I18N")
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
    interactionHUDEntry = false,

    nextStationPoint = nil,
    nextStationText = ""
}

function hud.draw(ts)
    hud.drawTrain()
    hud.drawExit()
    hud.drawDoor()
    hud.drawEntry()
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

function hud.drawEntry()
    if hud.entryVisible then
        hud.entryVisible = false
        utils.createInteractionHub(I18N.OnScreen("ingame_enter_station_msg"), "UI_Apply", true)
        hud.interactionHUDEntry = true
    else
        if hud.interactionHUDEntry then
            utils.createInteractionHub(I18N.OnScreen("ingame_enter_station_msg"), "UI_Apply", false)
        end
        hud.interactionHUDEntry = false
    end
end

function hud.drawExit()
    if hud.exitVisible then
        hud.exitVisible = false
        utils.createInteractionHub(I18N.OnScreen("ingame_exit_station_msg"), "UI_Apply", true)
        hud.interactionHUDExit = true
    else
        if hud.interactionHUDExit then
            utils.createInteractionHub(I18N.OnScreen("ingame_exit_station_msg"), "UI_Apply", false)
        end
        hud.interactionHUDExit = false
    end
end

function hud.drawDoor()
    if hud.doorVisible then
        hud.doorVisible = false
        utils.createInteractionHub(I18N.OnScreen("ingame_use_door_msg"), "UI_Apply", true) -- Spam it to make sure it really gets diplayed and not gets interrupted
        hud.interactionHUDDoor = true
    else
        if hud.interactionHUDDoor then
            utils.createInteractionHub(I18N.OnScreen("ingame_use_door_msg"), "UI_Apply", false)
        end
        hud.interactionHUDDoor = false
    end
end

function hud.drawTrain()
    if hud.trainVisible then
        hud.trainVisible = false
        utils.createInteractionHub(I18N.OnScreen("ingame_enter_train_msg"), "UI_Apply", true)
        hud.interactionHUDTrain = true
    else
        if hud.interactionHUDTrain then
            utils.createInteractionHub(I18N.OnScreen("ingame_enter_train_msg"), "UI_Apply", false)
        end
        hud.interactionHUDTrain = false
    end
end

function hud.drawDestinations(sys)
    local text = I18N.OnScreen("ingame_next_station_msg") ..":\n"

    for k, d in pairs(sys.pathsData) do
        local stationText = I18N.OnScreen(sys.stations[d.targetID].displayName)
        if k == sys.currentPathsIndex then
            text = text .. tostring(" [X] " .. stationText .. "\n")

            if observers.nextStationText ~= stationText then
                Game.GetMappinSystem():UnregisterMappin(observers.nextStationPoint)
                observers.nextStationText = stationText
                observers.nextStationPoint = Game.GetMappinSystem():RegisterMappin(MappinData.new({ mappinType = 'Mappins.DefaultStaticMappin', variant = 'CustomPositionVariant', visibleThroughWalls = true }), sys.stations[d.targetID].trainExit.pos)
            end

        else
            text = text .. tostring(" [  ] " .. stationText .. "\n")
        end
    end

    if not sys.ts.observers.hudText then return end

    sys.ts.observers.hudText:SetVisible(true)
    sys.ts.observers.hudText:SetText(text)
end

return hud