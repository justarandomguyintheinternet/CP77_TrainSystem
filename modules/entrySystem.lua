local entry = require("modules/classes/entry")
local utils = require("modules/utils/utils")
local Cron = require("modules/utils/Cron")

entrySys = {}

function entrySys:new(ts)
	local o = {}

    o.ts = ts
	o.entries = {}
    o.maxDistToEntry = 2.4
    o.elevatorIDS = {}

	self.__index = self
   	return setmetatable(o, self)
end

function entrySys:load()
    for _, file in pairs(dir("data/entries")) do
        if file.name:match("^.+(%..+)$") == ".json" then
            print(file.name)
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
                self.ts.hud.drawEntry(self.ts.stationSys.stations[closest.stationID])
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

    Cron.After(0.25, function ()
        Game.GetTeleportationFacility():Teleport(Game.GetPlayer(), entry.elevatorPosition, entry.elevatorPlayerRotation)
    end)
    Cron.After(entry.elevatorTime, function ()
        self.ts.stationSys:enter()
    end)
    Cron.After(entry.elevatorTime * 0.3, function ()
        self.ts.stationSys:loadStation(entry.stationID)
    end)
end

function entrySys:looksAtEntry(closest)
    local looksAt = false
    local target = Game.GetTargetingSystem():GetLookAtObject(Game.GetPlayer(), false, false)
    if target then
        if (target:GetClassName().value == "DataTerm" and not closest.useDoors) or (target:GetClassName().value == "FakeDoor" and closest.useDoors) then
            if utils.distanceVector(target:GetWorldPosition(), Game.GetPlayer():GetWorldPosition()) < self.maxDistToEntry then
                looksAt = true
            end
        end
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
                Game.FindEntityByID(self.elevatorIDS[e.stationID]):GetEntity():Destroy()
                self.elevatorIDS[e.stationID] = nil
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

return entrySys