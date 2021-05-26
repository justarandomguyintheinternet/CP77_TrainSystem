local debug = require("debug/logic/debug")

ts = {
    runtimeData = {
        cetOpen = false,
        inMenu = false,
        inGame = false
    },

    defaultSettings = {
        fallProtection = true
    },

    settings = {},
	CPS = require("CPStyling"),
    input = require("modules/utils/input"),
    observers = require("modules/utils/observers"),
    hud = require("modules/ui/hud"),
    Cron = require("modules/utils/Cron"),
    GameUI = require("modules/utils/GameUI")
}

function ts:new()
    registerForEvent("onInit", function()
        ts.entrySys = require("modules/entrySystem"):new(ts)
        ts.stationSys = require("modules/stationSystem"):new(ts)
        ts.entrySys:load()
        ts.stationSys:load()

        ts.observers.start()
        ts.input.startInputObserver()

        Observe('RadialWheelController', 'OnIsInMenuChanged', function(isInMenu) -- Setup observer and GameUI to detect inGame / inMenu
            ts.runtimeData.inMenu = isInMenu
        end)

        ts.GameUI.OnSessionStart(function()
            ts.runtimeData.inGame = true
        end)

        ts.GameUI.OnSessionEnd(function()
            ts.runtimeData.inGame = false
        end)

        ts.runtimeData.inGame = not ts.GameUI.IsDetached() -- Required to check if ingame after reloading all mods

        config.tryCreateConfig("data/config.json", ts.defaultSettings)
        ts.settings = config.loadFile("data/config.json")
    end)

    registerForEvent("onUpdate", function(deltaTime)
        if not ts.runtimeData.inMenu then
            debug.run(ts)
            ts.entrySys:update()
            ts.stationSys:update()
        end
        ts.Cron.Update(deltaTime)
    end)

    registerForEvent("onDraw", function()

    end)

    registerForEvent("onOverlayOpen", function()
        ts.runtimeData.cetOpen = true
    end)

    registerForEvent("onOverlayClose", function()
        ts.runtimeData.cetOpen = false
    end)

    return ts

end

return ts:new()