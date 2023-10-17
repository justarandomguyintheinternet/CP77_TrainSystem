-- Made by keanuWheeze, with the incredible help of the CP2077 Modding Community <3

local dependenciesInstalled = false

ts = {
    runtimeData = {
        cetOpen = false,
        inMenu = false,
        inGame = false
    },

    defaultSettings = {
        camDist = 16,
        trainSpeed = 24,
        defaultSeat = 1,
        moneyPerStation = 2,
        holdMult = 1,
        showImGui = false,
        elevatorTime = 7,
        uiLayout = 1, -- 1 = Vanilla, 2 = E3, 3 = Superior
        noHudTrain = false,
        unlockAllTracks = false,
        elevatorGlitch = true,
        trainGlitch = false,
        autoCenter = false,
        blueTrain = false,
        defaultFPP = false
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
    config = require("modules/utils/config"),
    debug = require("debug/logic/debug")
}

function ts:new()
    registerForEvent("onInit", function()
        local archiveInstalled = ModArchiveExists("trainSystem.archive") and ModArchiveExists("trainSystem_2.archive")
        local axlInstalled = ArchiveXL ~= nil
        local cwInstalled = Codeware ~= nil

        if not archiveInstalled then
            print("[MetroSystem] Error: \"trainSystem.archive\" or \"trainSystem_2.archive\" file could not be found inside \"archive/pc/mod\". Mod has been disabled to avoid crashes.")
            return
        end
        if not axlInstalled then
            print("[MetroSystem] Error: ArchiveXL is not installed. Mod has been disabled to avoid crashes.")
            return
        end
        if not cwInstalled then
            print("[MetroSystem] Error: Codeware is not installed. Mod has been disabled to avoid crashes.")
            return
        end
        dependenciesInstalled = true

        CName.add("train")
        self.utils.addTrainVehicle()

        self.config.tryCreateConfig("data/config.json", self.defaultSettings)
        self.config.backwardComp("data/config.json", self.defaultSettings)
        self.settings = self.config.loadFile("data/config.json")
        self.settingsUI.setupNative(self)

        self.entrySys = require("modules/entrySystem"):new(self)
        self.entrySys:load()

        self.routingSystem = require("modules/routingSystem"):new()
        self.routingSystem:load(self.settings.unlockAllTracks)

        -- self.stationSys = require("modules/stationSystem"):new(ts)
        -- self.stationSys:load()

        self.objectSys.initialize()
        self.observers.start(self)
        self.input.startInputObserver()

        self.Cron.Every(1.0, function ()
            self.utils.fixNoFastTravel()
        end)

        Observe('RadialWheelController', 'OnIsInMenuChanged', function(_, isInMenu) -- Setup observer and GameUI to detect inGame / inMenu
            self.runtimeData.inMenu = isInMenu
        end)

        self.GameUI.OnSessionStart(function()
            self.runtimeData.inGame = true
            self.routingSystem:load() -- Load again to handle Act 1
        end)

        self.GameUI.OnSessionEnd(function()
            self.runtimeData.inGame = false
            self.utils.forceStop(self)
        end)

        self.GameUI.OnPhotoModeOpen(function()
            self.runtimeData.inMenu = true
        end)

        self.GameUI.OnPhotoModeClose(function()
            self.runtimeData.inMenu = false
        end)

        self.runtimeData.inGame = not self.GameUI.IsDetached() -- Required to check if ingame after reloading all mods
    end)

    registerForEvent("onUpdate", function(deltaTime)
        if not dependenciesInstalled then return end

        if (not self.runtimeData.inMenu) and self.runtimeData.inGame and (math.floor(observers.timeDilation) ~= 0) and not observers.radioPopupActive then
            self.hud.drawInteraction()
            self.observers.update()
            self.entrySys:update()
            -- self.stationSys:update(deltaTime)
            self.Cron.Update(deltaTime)
            self.debug.baseUI.utilUI.update()
        elseif self.entrySys.forceRunCron then
            self.Cron.Update(deltaTime)
        -- elseif self.stationSys.activeTrain and observers.radioPopupActive then -- Always teleport, avoid issues with popups
            -- self.stationSys.activeTrain:updateEntity()
        end
    end)

    registerForEvent("onShutdown", function ()
        self.utils.forceStop(ts)
    end)

    registerForEvent("onDraw", function()
        if not dependenciesInstalled then return end

        if self.runtimeData.cetOpen then
            if self.settings.showImGui then
                self.settingsUI.draw(ts)
            end
            self.debug.run(ts)
        end
        -- if (not self.runtimeData.inMenu) and self.runtimeData.inGame then
        --     self.hud.draw(ts)
        -- end
    end)

    registerForEvent("onOverlayOpen", function()
        self.runtimeData.cetOpen = true
    end)

    registerForEvent("onOverlayClose", function()
        self.runtimeData.cetOpen = false
    end)

    return self
end

return ts:new()