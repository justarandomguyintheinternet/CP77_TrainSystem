input = {
    interactKey = false,
    exit = false,
    toggleCam = false,
    up = false,
    down = false
}

function input.startInputObserver()
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
        elseif actionName == 'UI_MoveDown' then
            if actionType == 'BUTTON_PRESSED' then
                input.down = true
            elseif actionType == 'BUTTON_RELEASED' then
                input.down = false
            end
        elseif actionName == 'UI_MoveUp' then
            if actionType == 'BUTTON_PRESSED' then
                input.up = true
            elseif actionType == 'BUTTON_RELEASED' then
                input.up = false
            end
        end
    end)
end

return input