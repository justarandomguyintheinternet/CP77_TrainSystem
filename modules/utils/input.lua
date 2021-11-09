input = {
    interactKey = false,
    exit = false,
    toggleCam = false,
    up = false,
    down = false
}

function input.startInputObserver()
    Observe('PlayerPuppet', 'OnGameAttached', function(this)
        input.startListeners(this)
    end)

    Observe('PlayerPuppet', 'OnAction', function(_, action)
        local actionName = Game.NameToString(action:GetName(action))
        local actionType = action:GetType(action).value
        if actionName == 'Choice1_Release' then
            if actionType == 'BUTTON_PRESSED' then
                input.interactKey = true
            elseif actionType == 'BUTTON_RELEASED' then
                input.interactKey = false
            end
        elseif actionName == 'Exit' then
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
                print("next")
                input.down = true
            end
        elseif actionName == 'PreviousWeapon' then
            if actionType == 'BUTTON_PRESSED' then
                print("last")
                input.up = true
            end
        end
    end)
end

function input.startListeners(player)
    player:RegisterInputListener(player, 'Choice1_Release')
    player:RegisterInputListener(player, 'Exit')
    player:RegisterInputListener(player, 'ToggleVehCamera')
    player:RegisterInputListener(player, 'NextWeapon')
    player:RegisterInputListener(player, 'PreviousWeapon')
end


return input