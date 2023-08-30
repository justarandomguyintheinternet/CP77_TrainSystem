local utils = require("modules/utils/utils")
local Cron = require("modules/utils/Cron")
local lang = require("modules/utils/lang")
local observers = require("modules/utils/observers")
local hud = require("modules/ui/hud")
local input = require("modules/utils/input")

entrySys = {}

function entrySys:new(ts)
	local o = {}

    o.ts = ts
	o.entries = {}
    o.maxDistToEntry = 2.6
    o.isLookingAtEntry = false
    o.targetEntry = nil

    o.elevatorIDS = {}
    o.forceRunCron = false

    o.mappinID = nil

	self.__index = self
   	return setmetatable(o, self)
end

function entrySys:load()
    self:registerKeybinds()

    for _, file in pairs(dir("data/entries")) do
        if file.name:match("^.+(%..+)$") == ".json" then
            local entry = require("modules/classes/entry"):new()
            entry:load("data/entries/" .. file.name)
            table.insert(self.entries, entry)
        end
    end
end

function entrySys:registerKeybinds()
    input.registerKeybind("map_input", "UI_Apply", function()
        if observers.onMap then
            self:markClosest()
        end
    end)

    input.registerKeybind("enter_station", "UI_Apply", function()
        if not self.isLookingAtEntry then return end

        local duration = 0
        if ts.settings.elevatorGlitch then
            duration = 0.6
            utils.playGlitchEffect("fast_travel_glitch", GetPlayer())
        end
        Cron.After(duration, function ()
            self:enter(self.targetEntry)
        end)
    end)
end

function entrySys:findEntryByID(id)
    for _, entry in pairs(self.entries) do
        if entry.stationID == id then return entry end
    end
end

function entrySys:update()
    local closest = self:getClosestEntry()
    if not closest then return end

    if self.mappinID and GetPlayer():GetWorldPosition():Distance(closest.waypointPosition) < closest.radius then
        Game.GetMappinSystem():UnregisterMappin(self.mappinID)
        self.mappinID = nil
    end

    self.isLookingAtEntry = false
    observers.noFastTravel = false

    if GetPlayer():GetWorldPosition():Distance(closest.center) > closest.radius then
        hud.toggleInteraction(false, "enter_station")
    end

    if not closest.useDoors then
        observers.noFastTravel = true
    end

    if not self:looksAtEntry(closest) then
        hud.toggleInteraction(false, "enter_station")
    end

    hud.toggleInteraction(true, "enter_station")
    self.isLookingAtEntry = true
    self.targetEntry = closest
end

function entrySys:enter(entry)
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

    utils.createInteractionHub(lang.getText("enter_station"), "UI_Apply", false)
    utils.playAudio(GetPlayer(), "dev_elevator_02_movement_start", 3)

    local playerElevatorPos = utils.subVector(entry.elevatorPosition, Vector4.new(0, 1.1, 0, 0))-- Adjusted to make the player stand less in front of the wall
    local playerSecondaryElevatorPos = utils.subVector(entry.secondaryPosition, Vector4.new(0, 1.1, 0, 0))

    if entry.useSecondaryElevator then -- Ugly af fix for too long distances
        Game.GetTeleportationFacility():Teleport(GetPlayer(), playerSecondaryElevatorPos, entry.elevatorPlayerRotation)
        Cron.After(0.25, function ()
            Game.GetTeleportationFacility():Teleport(GetPlayer(), playerElevatorPos, entry.elevatorPlayerRotation)
        end)
    else
        Game.GetTeleportationFacility():Teleport(GetPlayer(), playerElevatorPos, entry.elevatorPlayerRotation)
    end

    Cron.After(self.ts.settings.elevatorTime, function () -- Tp to station and more
        utils.stopAudio(GetPlayer(), "dev_elevator_02_movement_start")
        utils.playAudio(GetPlayer(), "dev_elevator_02_movement_stop", 3)
        local targetStation = self.ts.stationSys.stations[entry.stationID]
	    targetStation:tpTo(targetStation.portalPoint)
    end)

    Cron.After(self.ts.settings.elevatorTime - 0.6, function()
        if not self.ts.settings.elevatorGlitch then return end
        utils.playGlitchEffect("fast_travel_glitch", GetPlayer())
    end)
end

-- Checks if player is looking at an entry
---@param closest table
---@return boolean
function entrySys:looksAtEntry(closest)
    local target = Game.GetTargetingSystem():GetLookAtObject(GetPlayer(), false, false)

    if not target or not GetPlayer():GetFastTravelSystem():IsFastTravelEnabled() then return false end
    if not (target:GetClassName().value == "DataTerm" and not closest.useDoors) and not (target:GetClassName().value == "FakeDoor" and closest.useDoors) then return false end
    if not (utils.distanceVector(target:GetWorldPosition(), GetPlayer():GetWorldPosition()) < self.maxDistToEntry) then return false end

    return true
end

function entrySys:getClosestEntry()
    local closestEntry = nil
    local closestDist = 999999999999
    for _, entry in pairs(self.entries) do
        local distance = GetPlayer():GetWorldPosition():Distance(entry.center)
        if distance < closestDist then
            closestDist = distance
            closestEntry = entry
        end
    end
    return closestEntry
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