input = {
    interactKey = false,
    exit = false,
    toggleCam = false,
    up = false,
    down = false
}

function input.startInputObserver(ts)
    Observe('PlayerPuppet', 'OnGameAttached', function(this)
        input.startListeners(this)
    end)

    Observe('PlayerPuppet', 'OnAction', function(_, action)
        local actionName = Game.NameToString(action:GetName(action))
        local actionType = action:GetType(action).value
        if actionName == 'Exit' then
            if actionType == 'BUTTON_PRESSED' then
                input.exit = true
            elseif actionType == 'BUTTON_RELEASED' then
                input.exit = false
            end
        elseif actionName == 'ToggleVehCamera' then
            if actionType == 'BUTTON_PRESSED' then
                input.toggleCam = true
            elseif actionType == 'BUTTON_RELEASED' then
                input.toggleCam = false
            end
        elseif actionName == 'NextWeapon' then
            if actionType == 'BUTTON_PRESSED' then
                if ts.observers.radioPopupActive then return end
                input.down = true
            end
        elseif actionName == 'PreviousWeapon' then
            if actionType == 'BUTTON_PRESSED' then
                if ts.observers.radioPopupActive then return end
                input.up = true
            end
        elseif actionName == 'dpad_left' then
            if actionType == 'BUTTON_PRESSED' then
                input.down = true
            end
        elseif actionName == 'UI_Apply' then
            if actionType == 'BUTTON_PRESSED' then
                input.interactKey = true
                if ts.observers.onMap then
                    ts.entrySys:markClosest()
                end
            elseif actionType == 'BUTTON_RELEASED' then
                input.interactKey = false
            end
        elseif actionName == 'Choice2_Release' then
            if actionType == 'BUTTON_PRESSED' then
                if not ts.stationSys.activeTrain then return end
                if not ts.stationSys.activeTrain.playerMounted then return end
                if ts.stationSys.activeTrain.perspective ~= "fpp" then return end
                if ts.stationSys.activeTrain.currentSeat == 4 then return end
                if ts.observers.popupManager then
                    ts.observers.popupManager:SpawnVehicleRadioPopup()
                    ts.observers.radioPopupActive = true
                end
            end
        elseif actionName == 'DescriptionChange' then
            if actionType == 'BUTTON_PRESSED' then
                if not ts.stationSys.activeTrain then return end
                if not ts.stationSys.activeTrain.playerMounted then return end
                if ts.stationSys.activeTrain.perspective ~= "fpp" then return end
                if ts.stationSys.activeTrain.currentSeat == 4 then return end
                if ts.observers.popupManager then
                    ts.observers.popupManager:SpawnVehicleRadioPopup()
                    ts.observers.radioPopupActive = true
                end
            end
        end
    end)
end

function input.startListeners(player)
    player:UnregisterInputListener(player, 'Choice1_Release')
    player:UnregisterInputListener(player, 'Exit')
    player:UnregisterInputListener(player, 'ToggleVehCamera')
    player:UnregisterInputListener(player, 'NextWeapon')
    player:UnregisterInputListener(player, 'PreviousWeapon')
    player:UnregisterInputListener(player, 'UI_Apply')

    player:RegisterInputListener(player, 'Choice1_Release')
    player:RegisterInputListener(player, 'Exit')
    player:RegisterInputListener(player, 'ToggleVehCamera')
    player:RegisterInputListener(player, 'NextWeapon')
    player:RegisterInputListener(player, 'PreviousWeapon')
    player:RegisterInputListener(player, 'UI_Apply')
end


return input