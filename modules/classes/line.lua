local config = require("modules/utils/config")

line = {}

function line:new()
	local o = {}

    o.stations = {}
    o.name = ""
    o.audio = ""

	self.__index = self
   	return setmetatable(o, self)
end

function line:load(path)
    local data = config.loadFile(path)

    self.stations = data.stations
    self.name = data.name
    self.audio = data.audio
end

function line:save(path)
    local data = {}

    data.stations = self.stations
    data.name = self.name
    data.audio = self.audio

    config.saveFile(path, data)
end

return line