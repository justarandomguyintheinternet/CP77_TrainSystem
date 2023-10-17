input = {
    keybinds = {}
}

function input.registerKeybind(id, key, callback)
    input.keybinds[id] = {key = key, callback = callback}
end

function input.removeKeybind(id)
    input.keybinds[id] = nil
end

function input.startInputObserver()
    Observe('PlayerPuppet', 'OnAction', function(_, action)
        local actionName = Game.NameToString(action:GetName(action))
        local actionType = action:GetType(action).value

        if actionType == "BUTTON_PRESSED" then
            for _, bind in pairs(input.keybinds) do
                if bind.key == actionName then
                    bind.callback()
                end
            end
        end
    end)
end

return input