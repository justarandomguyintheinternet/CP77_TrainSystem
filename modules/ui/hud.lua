local utils = require("modules/utils/utils")
local lang = require("modules/utils/lang")
local observers = require("modules/utils/observers")

hud = {
    destVisible = false,
    interactions = {}
}

function hud.toggleInteraction(state, locKey)
    if not state and not hud.interactions[locKey] then return end

    if not state and hud.interactions[locKey] then
        hud.interactions[locKey] = nil
        utils.createInteractionHub(lang.getText(locKey), "UI_Apply", false)
        return
    end

    hud.interactions[locKey] = true
end

function hud.draw()
    hud.drawInteraction()

    if hud.destVisible then
        hud.drawDestinations()
    else
        if observers.hudText then
            observers.hudText:SetVisible(false)
        end
    end
end

function hud.drawInteraction()
    for key, _ in pairs(hud.interactions) do
        utils.createInteractionHub(lang.getText(key), "UI_Apply", true)
    end
end

function hud.drawDestinations()
    if not ts.observers.hudText then return end

    observers.hudText:SetVisible(true)
    observers.hudText:SetText("Line Info:")
end

return hud