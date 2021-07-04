input = {
    interactKey = false,
    exit = false
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
        end
    end)
end

return input