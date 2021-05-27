local point = require("modules/classes/point")
local config = require("modules/utils/config")
local utils = require("modules/utils/utils")

track = {}

function track:new()
	local o = {}

    o.points = {}
    o.id = 0
    o.connectedID = {first = {next = -1, last = -1}, second = {next = -1, last = -1}}
    o.hasStation = {next = -1, last = -1}

	self.__index = self
   	return setmetatable(o, self)
end

function track:load(path)
    local data = config.loadFile(path)

    for k, v in pairs(data.points) do
        local p = point:new()
        p:load(v)
        self.points[k] = p
    end

    self.id = data.id
    self.connectedID = data.connectedID
    self.hasStation = data.hasStation
end

function track:save(path)
    local data = {}

    data.id = self.id
    data.connectedID = self.connectedID
    data.hasStation = self.hasStation
    data.points = {}
    for k, p in pairs(self.points) do
        data.points[k] = p:getData()
    end

    config.saveFile(path, data)
end

return track