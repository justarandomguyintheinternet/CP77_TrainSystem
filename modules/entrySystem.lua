local entry = require("modules/classes/entry")
local utils = require("modules/utils/utils")
local Cron = require("modules/utils/Cron")
local settings = require("modules/utils/GameSettings")
local lang = require("modules/utils/lang")
local spawnEntities = false

entrySys = {}

function entrySys:new(ts)
	local o = {}

    o.ts = ts
	o.entries = {}
    o.maxDistToEntry = 2.6
    o.elevatorIDS = {}
    o.forceRunCron = false

    o.mappinID = nil

	self.__index = self
   	return setmetatable(o, self)
end

function entrySys:load()
    for _, file in pairs(dir("data/entries")) do
        if file.name:match("^.+(%..+)$") == ".json" then
            local e = entry:new()
            e:load("data/entries/" .. file.name)
            table.insert(self.entries, e)
        end
    end
end

function entrySys:findEntryByID(id)
    for _, v in pairs(self.entries) do
        if v.stationID == id then return v end
    end
end

function entrySys:update()
    --self:handleElevators()
    local closest = self:getClosestEntry()
    if closest then
        local dist = utils.distanceVector(GetPlayer():GetWorldPosition(), closest.center)
        if dist < closest.radius then
            if not closest.useDoors then
                self.ts.observers.noFastTravel = true
            end
            if self:looksAtEntry(closest) then
                if closest.useDoors then
                    self.ts.hud.entryVisible = true
                end
                if self.ts.input.interactKey then
                    self.ts.input.interactKey = false
                    if self.ts.stationSys.currentStation == nil then

                        local t = 0
                        if ts.settings.elevatorGlitch then
                            t = 0.6
                            utils.playGlitchEffect("fast_travel_glitch", GetPlayer())
                        end
                        Cron.After(t, function ()
                            self:enter(closest)
                        end)

                    end
                end
            end
        else
            self.ts.observers.noFastTravel = false
        end

        if self.mappinID and utils.distanceVector(GetPlayer():GetWorldPosition(), closest.waypointPosition) < closest.radius then
            pcall(function ()
                Game.GetMappinSystem():UnregisterMappin(self.mappinID)
                self.mappinID = nil
            end)
        end
    end
end

function entrySys:enter(entry)
    self.ts.observers.noSave = true
    self.ts.observers.noTrains = true

    if self.mappinID then
        pcall(function ()
            Game.GetMappinSystem():UnregisterMappin(self.mappinID)
        end)
    end
    self.mappinID = nil

    self.forceRunCron = true
    Cron.Every(0.05, {tick = 0}, function(timer)
        if timer.tick < 1 then
            timer.tick = timer.tick + 0.05
            Game.GetUISystem():QueueEvent(ForceCloseHubMenuEvent.new())
        else
            self.forceRunCron = false
            timer:Halt()
        end
	end)

    utils.applyStatus("GameplayRestriction.NoCombat")
    utils.changeZoneIndicatorSafe()

    utils.createInteractionHub(lang.getText("enter_station"), "UI_Apply", false)
    self.ts.stationSys.inputHintsOriginal = settings.Get("/interface/hud/input_hints")
    settings.Set("/interface/hud/input_hints", false)

    self.ts.stationSys.jobTrackerOriginal = settings.Get("/interface/hud/quest_tracker")
    settings.Set("/interface/hud/quest_tracker", true)

    utils.playAudio(GetPlayer(), "dev_elevator_02_movement_start", 3)

    local playerElevatorPos = utils.subVector(entry.elevatorPosition, Vector4.new(0, 1.1, 0, 0))-- Adjusted to make the player stand less in front of the wall
    local playerSecondaryElevatorPos = utils.subVector(entry.secondaryPosition, Vector4.new(0, 1.1, 0, 0))

    if entry.useSecondaryElevator then -- Ugly af fix for too long distances
        local secondID = utils.spawnObject(entry.elevatorPath, playerSecondaryElevatorPos, EulerAngles.new(0, 0, 0):ToQuat())
        Game.GetTeleportationFacility():Teleport(GetPlayer(), playerSecondaryElevatorPos, entry.elevatorPlayerRotation)
        Cron.After(0.25, function ()
            Game.GetTeleportationFacility():Teleport(GetPlayer(), playerElevatorPos, entry.elevatorPlayerRotation)
        end)
        Cron.After(0.5, function ()
            if not spawnEntities then return end

            exEntitySpawner.Despawn(Game.FindEntityByID(secondID))
            secondID = nil
        end)
    else
        Game.GetTeleportationFacility():Teleport(GetPlayer(), playerElevatorPos, entry.elevatorPlayerRotation)
    end

    Cron.After(self.ts.settings.elevatorTime, function () -- Tp to station and more
        utils.stopAudio(GetPlayer(), "dev_elevator_02_movement_start")
        utils.playAudio(GetPlayer(), "dev_elevator_02_movement_stop", 3)
        self.ts.stationSys:enter()
    end)

    Cron.After(self.ts.settings.elevatorTime * 0.7, function () -- Spawn station objects
        self.ts.stationSys:loadStation(entry.stationID)
    end)

    Cron.After(self.ts.settings.elevatorTime - 0.6, function()
        if not self.ts.settings.elevatorGlitch then return end
        utils.playGlitchEffect("fast_travel_glitch", GetPlayer())
    end)
end

function entrySys:looksAtEntry(closest)
    local looksAt = false
    local target = Game.GetTargetingSystem():GetLookAtObject(GetPlayer(), false, false)
    if target and GetPlayer():GetFastTravelSystem():IsFastTravelEnabled() then
        if (target:GetClassName().value == "DataTerm" and not closest.useDoors) or (target:GetClassName().value == "FakeDoor" and closest.useDoors) then
            if utils.distanceVector(target:GetWorldPosition(), GetPlayer():GetWorldPosition()) < self.maxDistToEntry then
                looksAt = true
                utils.createInteractionHub(lang.getText("enter_station"), "UI_Apply", true)
            else
                utils.createInteractionHub(lang.getText("enter_station"), "UI_Apply", false)
            end
        end
    else
        utils.createInteractionHub(lang.getText("enter_station"), "UI_Apply", false)
    end
    return looksAt
end

function entrySys:getClosestEntry()
    local closestEntry = nil
    local dist = 999999999999
    for _, v in pairs(self.entries) do
        local x = utils.distanceVector(GetPlayer():GetWorldPosition(), v.center)
        if x < dist then
            dist = x
            closestEntry = v
        end
    end
    return closestEntry
end

function entrySys:handleElevators()
    for _, e in pairs(self.entries) do
        local station = self.ts.stationSys.stations[e.stationID]

        local entryDist = utils.distanceVector(GetPlayer():GetWorldPosition(), e.center)
        local stationDist = utils.distanceVector(GetPlayer():GetWorldPosition(), station.center)

        if ((entryDist < 100) or (stationDist < 100)) then
            if self.elevatorIDS[e.stationID] == nil then
                self.elevatorIDS[e.stationID] = utils.spawnObject(e.elevatorPath, e.elevatorPosition, EulerAngles.new(0, 0, 0):ToQuat())
            end
        else
            if self.elevatorIDS[e.stationID] ~= nil then
                if Game.FindEntityByID(self.elevatorIDS[e.stationID]) ~= nil then
                    exEntitySpawner.Despawn(Game.FindEntityByID(self.elevatorIDS[e.stationID]))
                    self.elevatorIDS[e.stationID] = nil
                end
            end
        end
    end
end

function entrySys:despawnElevators()
    for _, id in pairs(self.elevatorIDS) do
        if id and Game.FindEntityByID(id) ~= nil then
            exEntitySpawner.Despawn(Game.FindEntityByID(id))
        end
    end
    self.elevatorIDS = {}
end

function entrySys:markClosest()
    if not self.ts.observers.worldMap then return end
    self.ts.observers.worldMap:UntrackCustomPositionMappin()
    self.ts.observers.worldMap:UntrackMappin()
    self.ts.observers.worldMap:SetCustomFilter(gamedataWorldMapFilter.FastTravel)

    local closest = self:getClosestEntry()
    self.mappinID = Game.GetMappinSystem():RegisterMappin(MappinData.new({ mappinType = 'Mappins.DefaultStaticMappin', variant = 'CustomPositionVariant', visibleThroughWalls = true }), closest.waypointPosition)
end

return entrySys