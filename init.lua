-- Made by keanuWheeze, with the incredible help of the CP2077 Modding Community <3

ts = {
    runtimeData = {
        cetOpen = false,
        inMenu = false,
        inGame = false,
        archiveInstalled = false
    },

    defaultSettings = {
        camDist = 16,
        trainSpeed = 24,
        defaultSeat = 2,
        moneyPerStation = 2,
        holdMult = 1,
        tppOnly = false,
        showImGui = false,
        elevatorTime = 7,
        uiLayout = 1, -- 1 = Vanilla, 2 = E3, 3 = Superior
        tppOffset = 2,
        noHudTrain = false
    },

    settings = {},
	CPS = require("CPStyling"),
    input = require("modules/utils/input"),
    observers = require("modules/utils/observers"),
    objectSys = require("modules/objectSystem"),
    hud = require("modules/ui/hud"),
    settingsUI = require("modules/ui/settingsUI"),
    Cron = require("modules/utils/Cron"),
    GameUI = require("modules/utils/GameUI"),

    utils = require("modules/utils/utils"),
    config = require("modules/utils/config")
    --debug = require("debug/logic/debug")
}

function ts:new()
    registerForEvent("onInit", function()
        ts.archiveInstalled = ModArchiveExists("trainSystem.archive")
        if not ts.archiveInstalled then
            print("[MetroSystem] Error: \"trainSystem.archive\" file could not be found inside \"archive/pc/mod\". Mod has been disabled to avoid crashes.")
            return
        end

        ts.config.tryCreateConfig("data/config.json", ts.defaultSettings)
        ts.config.backwardComp("data/config.json", ts.defaultSettings)
        ts.settings = ts.config.loadFile("data/config.json")
        ts.settingsUI.setupNative(ts)

        ts.entrySys = require("modules/entrySystem"):new(ts)
        ts.stationSys = require("modules/stationSystem"):new(ts)
        ts.trackSys = require("modules/trackSystem"):new(ts)

        ts.trackSys:load()
        ts.entrySys:load()
        ts.stationSys:load()
        ts.objectSys.initialize()

        ts.observers.start(ts)
        ts.input.startInputObserver(ts)
        ts.input.startListeners(Game.GetPlayer())

        ts.Cron.Every(1.0, function ()
            ts.utils.fixNoFastTravel()
        end)

        Observe('RadialWheelController', 'OnIsInMenuChanged', function(_, isInMenu) -- Setup observer and GameUI to detect inGame / inMenu
            ts.runtimeData.inMenu = isInMenu
        end)

        ts.GameUI.OnSessionStart(function()
            ts.runtimeData.inGame = true
            ts.trackSys:load() -- Load again to handle Act 1
        end)

        ts.GameUI.OnSessionEnd(function()
            ts.runtimeData.inGame = false
            ts.utils.forceStop(ts)
        end)

        ts.GameUI.OnPhotoModeOpen(function()
            ts.runtimeData.inMenu = true
        end)

        ts.GameUI.OnPhotoModeClose(function()
            ts.runtimeData.inMenu = false
        end)

        ts.runtimeData.inGame = not ts.GameUI.IsDetached() -- Required to check if ingame after reloading all mods
    end)

    registerForEvent("onUpdate", function(deltaTime)
        if not ts.archiveInstalled then return end

        if (not ts.runtimeData.inMenu) and ts.runtimeData.inGame and (math.floor(observers.timeDilation) ~= 0) and ts.archiveInstalled then
            ts.observers.update()
            ts.entrySys:update()
            ts.stationSys:update(deltaTime)
            ts.objectSys.run()
            ts.Cron.Update(deltaTime)
            ts.input.interactKey = false -- Fix "sticky" input
            --ts.debug.baseUI.utilUI.update()
        elseif ts.entrySys.forceRunCron and ts.archiveInstalled then
            ts.Cron.Update(deltaTime)
        end
    end)

    registerForEvent("onShutdown", function ()
        ts.utils.forceStop(ts)
    end)

    registerForEvent("onDraw", function()
        if not ts.archiveInstalled then return end

        if ts.runtimeData.cetOpen then
            if ts.settings.showImGui then
                ts.settingsUI.draw(ts)
            end
            --ts.debug.run(ts)
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