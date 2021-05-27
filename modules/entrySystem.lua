local entry = require("modules/classes/entry")
local utils = require("modules/utils/utils")

entrySys = {}

function entrySys:new(ts)
	local o = {}

    o.ts = ts
	o.entries = {}
    o.maxDistToEntry = 2.4

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

function entrySys:update()
    local closest = self:getClosestEntry()
    if closest then
        local dist = utils.distanceVector(Game.GetPlayer():GetWorldPosition(), closest.center)
        if dist < closest.radius then
            self.ts.observers.noFastTravel = true
            if self:looksAtEntry(closest) then
                self.ts.hud.drawEntry(self.ts.stationSys.stations[closest.stationID])
                if self.ts.input.interactKey then
                    self.ts.input.interactKey = false
                    if self.ts.stationSys.currentStation == nil then
                        self.ts.stationSys:enter(closest.stationID)
                    end
                end
            end
        else
            self.ts.observers.noFastTravel = false
        end
    end
end

function entrySys:looksAtEntry(closest)
    local looksAt = false
    local target = Game.GetTargetingSystem():GetLookAtObject(Game.GetPlayer(), false, false)
    if target then
        if target:GetClassName().value == "DataTerm" or (target:GetClassName().value == "FakeDoor" and closest.useDoors) then
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

function entrySys:placePin()

end

function entrySys:removePin()

end

return entrySys