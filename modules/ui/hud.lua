local utils = require("modules/utils/utils")
local lang = require("modules/utils/lang")
local observers = require("modules/utils/observers")

hud = {
    destVisible = false,

    interactionActive = false,
    locKey = ""
}

function hud.toggleInteraction(state, locKey)
    if not state then
        utils.createInteractionHub(lang.getText(hud.locKey), "UI_Apply", false)
    end

    hud.interactionActive = state
    hud.locKey = locKey
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
    if hud.interactionActive then
        utils.createInteractionHub(lang.getText(hud.locKey), "UI_Apply", true)
    end
end

function hud.drawDestinations()
    if not ts.observers.hudText then return end

    observers.hudText:SetVisible(true)
    observers.hudText:SetText("Line Info:")
end

return hud