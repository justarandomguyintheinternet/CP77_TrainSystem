local config = require("modules/utils/config")

line = {}

function line:new()
	local o = {}

    o.stations = {}
    o.name = ""
    o.audio = ""
    o.color = {}

    o.towards = 0 -- Used for directional lines at runtime
    o.id = 0

	self.__index = self
   	return setmetatable(o, self)
end

function line:load(path)
    local data = config.loadFile(path)

    self.stations = data.stations
    self.name = data.name
    self.audio = data.audio
    self.color = data.color
end

function line:save(path)
    local data = {}

    data.stations = self.stations
    data.name = self.name
    data.audio = self.audio
    data.color = self.color

    config.saveFile(path, data)
end

return line