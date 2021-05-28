local utils = require("modules/utils/utils")

point = {}

function point:new()
	local o = {}

    o.pos = Vector4.new(0, 0, 0, 0)
    o.rot = Quaternion.new(0, 0, 0, 0)
    o.loadStation = {next = false, last = false}
    o.unloadStation = {next = false, last = false}
    o.dir = ""

	self.__index = self
   	return setmetatable(o, self)
end

function point:load(data)
    self.pos = utils.getVector(data.pos)
    self.rot = utils.getQuaternion(data.rot)
    self.loadStation = data.loadStation
    self.unloadStation = data.unloadStation
end

function point:getData()
    local data = {}

    data.pos = utils.fromVector(self.pos)
    data.rot = utils.fromQuaternion(self.rot)
    data.loadStation = self.loadStation
    data.unloadStation = self.unloadStation

    return data
end

return point