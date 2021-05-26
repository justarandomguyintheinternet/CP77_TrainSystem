local config = require("modules/utils/config")
local utils = require("modules/utils/utils")

entry = {}

function entry:new()
	local o = {}

    o.center = Vector4.new(0, 0, 0, 0)
    o.radius = 0
    o.waypointPosition = Vector4.new(0, 0, 0, 0)
    o.useDoors = false
    o.stationID = 0

	self.__index = self
   	return setmetatable(o, self)
end

function entry:load(path)
    local data = config.loadFile(path)

    self.center = utils.getVector(data.center)
    self.radius = data.radius
    self.waypointPosition = utils.getVector(data.waypointPosition)
    self.useDoors = data.useDoors
    self.stationID = data.stationID
end

function entry:save(path)
    local data = {}

    data.center = utils.fromVector(self.center)
    data.waypointPosition = utils.fromVector(self.waypointPosition)
    data.useDoors = self.useDoors
    data.radius = self.radius
    data.stationID = self.stationID

    config.saveFile(path, data)
end

return entry