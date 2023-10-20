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
    o.stations = {}

    o.maxDistToPortal = 2.65
    o.isLookingAtPortal = false
    o.portalData = nil
    o.isMoving = false

    o.mappin = nil

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

    for _, file in pairs(dir("data/stations")) do
        if file.name:match("^.+(%..+)$") == ".json" then
            local s = require("modules/classes/station"):new(self.ts)
            s:load("data/stations/" .. file.name)
            self.stations[s.id] = s
        end
    end
end

function entrySys:sessionEnd()
    if self.mappin then
        Game.GetMappinSystem():UnregisterMappin(self.mappin)
        self.mappin = nil
    end
end

function entrySys:registerKeybinds()
    input.registerKeybind("map_input", "UI_Apply", function()
        if observers.onMap then
            self:markClosest()
        end
    end)

    input.registerKeybind("enter_station", "UI_Apply", function()
        if not self.isLookingAtPortal then return end

        local duration = 0
        if ts.settings.elevatorGlitch then
            duration = 0.6
            utils.playGlitchEffect("fast_travel_glitch", GetPlayer())
        end
        Cron.After(duration, function ()
            self:usePortal()
        end)
    end)
end

function entrySys:findEntryByID(id)
    for _, entry in pairs(self.entries) do
        if entry.stationID == id then return entry end
    end
end

function entrySys:checkEntry()
    local closest = self:getClosest(self.entries)
    if not closest then return end

    if self:looksAtEntry(closest) then
        observers.noFastTravel = true
        self.isLookingAtPortal = true
        self.portalData = {entry = closest, action = "enter"}
        return true
    else
        observers.noFastTravel = false
        return false
    end
end

function entrySys:handleWaypoint(closest)
    local inRange = GetPlayer():GetWorldPosition():Distance(closest.portalPoint.pos) < 14

    if inRange and not self.mappin then
        local mappinData = gamemappinsMappinData.new()
        mappinData.mappinType = TweakDBID.new('Mappins.DefaultStaticMappin')
        mappinData.variant = gamedataMappinVariant.GetInVariant
        mappinData.visibleThroughWalls = true
        self.mappin = Game.GetMappinSystem():RegisterMappin(mappinData, Vector4.new(closest.portalPoint.pos.x, closest.portalPoint.pos.y, closest.portalPoint.pos.z + 1, 0))
    elseif not inRange and self.mappin then
        Game.GetMappinSystem():UnregisterMappin(self.mappin)
        self.mappin = nil
    end
end

function entrySys:checkExit()
    local closest = self:getClosest(self.stations)
    if not closest then return end

    self:handleWaypoint(closest)

    if self:looksAtExit(closest) then
        self.isLookingAtPortal = true
        self.portalData = {entry = self:findEntryByID(closest.id), action = "exit"}
        return true
    else
        return false
    end
end

function entrySys:update()
    self.isLookingAtPortal = false
    observers.noFastTravel = false

    local hasEntry = self:checkEntry()
    local hasExit = self:checkExit()

    if self.isMoving then return end

    if hasEntry then
        hud.toggleInteraction(true, "enter_station")
    elseif hasExit then
        hud.toggleInteraction(true, "exit_station")
    else
        hud.toggleInteraction(false, "exit_station")
        hud.toggleInteraction(false, "enter_station")
        self.portalData = nil
    end
end

function entrySys:usePortal()
    if not self.portalData then return end

    local entry = self.portalData.entry
    self.isMoving = true

    Cron.After(0.1, function () -- Avoid getting overriden by the station's noSave zone being exited
        observers.noSave = true
    end)

    Cron.After(self.ts.settings.elevatorTime, function () -- Run this first as this unsets the isMoving, and if anything else fails this at least runs
        self.isMoving = false
        utils.stopAudio(GetPlayer(), "dev_elevator_02_movement_start")
        utils.playAudio(GetPlayer(), "dev_elevator_02_movement_stop", 3)

        local target = self.stations[entry.stationID].portalPoint
        if self.portalData.action == "exit" then
            target = self.stations[entry.stationID].groundPoint
            observers.noSave = false
        end

        utils.tp(GetPlayer(), target.pos, target.rot)
        Game.GetScriptableSystemsContainer():Get("PreventionSystem"):OnSetWantedLevel(SetWantedLevel.new({wantedLevel =EPreventionHeatStage.Heat_0 }))
    end)

    hud.toggleInteraction(false, "enter_station")
    hud.toggleInteraction(false, "exit_station")
    utils.playAudio(GetPlayer(), "dev_elevator_02_movement_start", 3)

    local playerElevatorPos = utils.subVector(entry.elevatorPosition, Vector4.new(0, 1.1, 0, 0)) -- Adjusted to make the player stand less in front of the wall
    local playerSecondaryElevatorPos = utils.subVector(entry.secondaryPosition, Vector4.new(0, 1.1, 0, 0))

    if entry.useSecondaryElevator then -- Ugly af fix for too long distances
        local pos1 = playerSecondaryElevatorPos
        local pos2 = playerElevatorPos

        if self.portalData.action == "exit" then
            pos1 = playerElevatorPos
            pos2 = playerSecondaryElevatorPos
        end

        utils.tp(GetPlayer(), pos1, entry.elevatorPlayerRotation)
        Cron.After(0.25, function ()
            utils.tp(GetPlayer(), pos2, entry.elevatorPlayerRotation)
        end)
    else
        utils.tp(GetPlayer(), playerElevatorPos, entry.elevatorPlayerRotation)
    end

    Cron.After(self.ts.settings.elevatorTime - 0.6, function()
        if not self.ts.settings.elevatorGlitch then return end
        utils.playGlitchEffect("fast_travel_glitch", GetPlayer())
    end)
end

-- Checks if player is looking at an exit, and is in range of station
---@param closest table
---@return boolean
function entrySys:looksAtExit(closest)
    local target = Game.GetTargetingSystem():GetLookAtObject(GetPlayer(), false, true)

    if not target then return false end
    if GetPlayer():GetWorldPosition():Distance(closest.center) > closest.radius then return false end
    if not utils.isVector(target:GetWorldPosition(), closest.exitDoorPosition) then return false end

    if closest.exitDoorSealed then
        pcall(function ()
            utils.lockDoor(target)
        end)
    end

    if Vector4.Distance(GetPlayer():GetWorldPosition(), target:GetWorldPosition()) > self.maxDistToPortal then return false end

	return true
end

-- Checks if player is looking at an entry, and is in range of entry
---@param closest table
---@return boolean
function entrySys:looksAtEntry(closest)
    local target = Game.GetTargetingSystem():GetLookAtObject(GetPlayer(), false, false)

    if not target then return false end
    if not (utils.distanceVector(target:GetWorldPosition(), GetPlayer():GetWorldPosition()) < self.maxDistToPortal) then return false end
    if not target or not GetPlayer():GetFastTravelSystem():IsFastTravelEnabled() then return false end
    if not (target:GetClassName().value == "DataTerm" and not closest.useDoors) and not (target:GetClassName().value == "FakeDoor" and closest.useDoors) then return false end

    return true
end

function entrySys:getClosest(data)
    local closest = nil
    local closestDist = 999999999999

    for _, location in pairs(data) do
        local distance = GetPlayer():GetWorldPosition():Distance(location.center)
        if distance < closestDist then
            closestDist = distance
            closest = location
        end
    end
    return closest
end

function entrySys:markClosest()
    if not self.ts.observers.worldMap then return end
    self.ts.observers.worldMap:UntrackCustomPositionMappin()
    self.ts.observers.worldMap:UntrackMappin()
    self.ts.observers.worldMap:SetCustomFilter(gamedataWorldMapFilter.FastTravel)

    local closest = self:getClosest(self.entries)
    Game.GetMappinSystem():RegisterMappin(MappinData.new({ mappinType = 'Mappins.DefaultStaticMappin', variant = 'CustomPositionVariant', visibleThroughWalls = true }), closest.waypointPosition)
end

return entrySys