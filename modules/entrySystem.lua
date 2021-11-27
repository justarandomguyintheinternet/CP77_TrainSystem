local entry = require("modules/classes/entry")
local utils = require("modules/utils/utils")
local Cron = require("modules/utils/Cron")
local settings = require("modules/utils/GameSettings")

entrySys = {}

function entrySys:new(ts)
	local o = {}

    o.ts = ts
	o.entries = {}
    o.maxDistToEntry = 2.6
    o.elevatorIDS = {}
    o.soundID = nil

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
    self:handleElevators()
    local closest = self:getClosestEntry()
    if closest then
        local dist = utils.distanceVector(Game.GetPlayer():GetWorldPosition(), closest.center)
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
                        self:enter(closest)
                    end
                end
            end
        else
            self.ts.observers.noFastTravel = false
        end
    end
end

function entrySys:enter(entry)
    self.ts.observers.noSave = true
    self.ts.observers.noKnockdown = true
    self.ts.runtimeData.noTrains = true

    Game.ApplyEffectOnPlayer("GameplayRestriction.NoCombat")
    Game.ChangeZoneIndicatorSafe()

    utils.createInteractionHub("Enter NCART Station", "UI_Apply", false)
    self.ts.stationSys.inputHintsOriginal = settings.Get("/interface/hud/input_hints")
    settings.Set("/interface/hud/input_hints", false)

    self.ts.stationSys.jobTrackerOriginal = settings.Get("/interface/hud/quest_tracker")
    settings.Set("/interface/hud/quest_tracker", true)

    self.soundID = utils.spawnObject("base\\fx\\meshes\\cyberparticles\\q110_blackwall.ent", entry.elevatorPosition, Quaternion.new(0, 0, 0, 0)) -- Sounds like an elevator?

    if entry.useSecondaryElevator then -- Ugly af fix for too long distances
        local secondID = utils.spawnObject(entry.elevatorPath, entry.secondaryPosition, EulerAngles.new(0, 0, 0):ToQuat())
        Game.GetTeleportationFacility():Teleport(Game.GetPlayer(), entry.secondaryPosition, entry.elevatorPlayerRotation)
        Cron.After(0.25, function ()
            Game.GetTeleportationFacility():Teleport(Game.GetPlayer(), entry.elevatorPosition, entry.elevatorPlayerRotation)
        end)
        Cron.After(0.5, function ()
            Game.FindEntityByID(secondID):GetEntity():Destroy()
            secondID = nil
        end)
    else
        Game.GetTeleportationFacility():Teleport(Game.GetPlayer(), entry.elevatorPosition, entry.elevatorPlayerRotation)
    end

    Cron.After(entry.elevatorTime, function () -- Tp to station and more
        self.ts.stationSys:enter()
        Game.FindEntityByID(self.soundID):GetEntity():Destroy()
    end)

    Cron.After(entry.elevatorTime * 0.7, function () -- Spawn station objects
        self.ts.stationSys:loadStation(entry.stationID)
    end)
end

function entrySys:looksAtEntry(closest)
    local looksAt = false
    local target = Game.GetTargetingSystem():GetLookAtObject(Game.GetPlayer(), false, false)
    if target and GetPlayer():GetFastTravelSystem():IsFastTravelEnabled() then
        if (target:GetClassName().value == "DataTerm" and not closest.useDoors) or (target:GetClassName().value == "FakeDoor" and closest.useDoors) then
            if utils.distanceVector(target:GetWorldPosition(), Game.GetPlayer():GetWorldPosition()) < self.maxDistToEntry then
                looksAt = true
                utils.createInteractionHub("Enter NCART Station", "UI_Apply", true)
            else
                utils.createInteractionHub("Enter NCART Station", "UI_Apply", false)
            end
        end
    else
        utils.createInteractionHub("Enter NCART Station", "UI_Apply", false)
    end
    return looksAt
end

function entrySys:getClosestEntry()
    local closestEntry = nil
    local dist = 999999999999
    for _, v in pairs(self.entries) do
        local x = utils.distanceVector(Game.GetPlayer():GetWorldPosition(), v.center)
        if x < dist then
            dist = x
            closestEntry = v
        end
    end
    return closestEntry
end

function entrySys:handleElevators()
    for _, e in pairs(self.entries) do
        local x = utils.distanceVector(Game.GetPlayer():GetWorldPosition(), e.center)
        local station = self.ts.stationSys.stations[e.stationID]
        if (x < utils.distanceVector(e.center, station.center) + station.radius) then
            if self.elevatorIDS[e.stationID] == nil then
                self.elevatorIDS[e.stationID] = utils.spawnObject(e.elevatorPath, e.elevatorPosition, EulerAngles.new(0, 0, 0):ToQuat())
            end
        else
            if self.elevatorIDS[e.stationID] ~= nil then
                if Game.FindEntityByID(self.elevatorIDS[e.stationID]) ~= nil then
                    Game.FindEntityByID(self.elevatorIDS[e.stationID]):GetEntity():Destroy()
                    self.elevatorIDS[e.stationID] = nil
                end
            end
        end
    end
end

function entrySys:despawnElevators()
    for _, id in pairs(self.elevatorIDS) do
        if id and Game.FindEntityByID(id) ~= nil then
            Game.FindEntityByID(id):GetEntity():Destroy()
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
    Game.GetMappinSystem():RegisterMappin(MappinData.new({ mappinType = 'Mappins.DefaultStaticMappin', variant = 'CustomPositionVariant', visibleThroughWalls = true }), closest.waypointPosition)
end

return entrySys