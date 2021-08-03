local debug = require("debug/logic/debug")

ts = {
    runtimeData = {
        cetOpen = false,
        inMenu = false,
        inGame = false,
        noTrains = false
    },

    defaultSettings = {
        fallProtection = true,
        camDist = 20,
        defaultSeat = 1,
        defaultStation = 1
    },

    settings = {},
	CPS = require("CPStyling"),
    input = require("modules/utils/input"),
    observers = require("modules/utils/observers"),
    objectSys = require("modules/objectSystem"),
    hud = require("modules/ui/hud"),
    settingsUI = require("modules/ui/settingsUI"),
    Cron = require("modules/utils/Cron"),
    GameUI = require("modules/utils/GameUI")
}

function ts:new()
    registerForEvent("onInit", function()
        ts.entrySys = require("modules/entrySystem"):new(ts)
        ts.stationSys = require("modules/stationSystem"):new(ts)
        ts.trackSys = require("modules/trackSystem"):new(ts)

        ts.trackSys:load()
        ts.entrySys:load()
        ts.stationSys:load()
        ts.objectSys.initialize()

        ts.observers.start(ts)
        ts.input.startInputObserver()

        Observe('RadialWheelController', 'OnIsInMenuChanged', function(_, isInMenu) -- Setup observer and GameUI to detect inGame / inMenu
            ts.runtimeData.inMenu = isInMenu
        end)

        ts.GameUI.OnSessionStart(function()
            ts.runtimeData.inGame = true
        end)

        ts.GameUI.OnSessionEnd(function()
            ts.runtimeData.inGame = false
            ts.entrySys:despawnElevators()
            ts.objectSys.despawnAll()
        end)

        ts.runtimeData.inGame = not ts.GameUI.IsDetached() -- Required to check if ingame after reloading all mods

        config.tryCreateConfig("data/config.json", ts.defaultSettings)
        ts.settings = config.loadFile("data/config.json")
    end)

    registerForEvent("onUpdate", function(deltaTime)
        if (not ts.runtimeData.inMenu) and ts.runtimeData.inGame then
            ts.observers.update()
            ts.entrySys:update()
            ts.stationSys:update(deltaTime)
            ts.objectSys.run()
        end
        ts.Cron.Update(deltaTime) --??????
    end)

    registerForEvent("onShutdown", function ()
        ts.entrySys:despawnElevators()
        ts.objectSys.despawnAll()
    end)

    registerForEvent("onDraw", function()
        if ts.runtimeData.cetOpen then
            ts.settingsUI.draw(ts)
            debug.run(ts)
        end
        if (not ts.runtimeData.inMenu) and ts.runtimeData.inGame then
            ts.hud.draw(ts)
        end
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