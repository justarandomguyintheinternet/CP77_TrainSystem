input = {
    interactKey = false,
    exit = false,
    toggleCam = false,
    up = false,
    down = false,

    keybinds = {}
}

function input.registerKeybind(id, key, callback)
    input.keybinds[id] = {key = key, callback = callback}
end

function input.removeKeybind(id)
    input.keybinds[id] = nil
end

function input.startInputObserver(ts)
    Observe('PlayerPuppet', 'OnGameAttached', function(this)
        input.startListeners(this)
    end)

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