local config = require("modules/utils/config")

track = {}

function track:new()
	local o = {}

    o.id = 0
    o.points = {}
    o.connectedID = {first = {back = -1, front = -1}, second = {back = -1, front = -1}}
    o.station = {back = -1, front = -1}
    o.connections = {}

	self.__index = self
   	return setmetatable(o, self)
end

-- Get table with all the connecting track's id's
local function getTrackConnections(track)
	local ids = {}

	table.insert(ids, track.connectedID.first.back)
	table.insert(ids, track.connectedID.first.front)
	table.insert(ids, track.connectedID.second.back)
	table.insert(ids, track.connectedID.second.front)

	return ids
end

-- Is the station somewhere on this track
---@param station number
---@return boolean
function track:hasStation(id)
	if self.station.back == id or self.station.front == id then
		return true
	end
	return false
end

--- Checks if there is any station on this track
---@return boolean
function track:hasAnyStation()
    return self.station.front ~= -1 and self.station.back ~= -1
end

function track:load(path)
    local data = config.loadFile(path)

    for key, pData in pairs(data.points) do
        local point = require("modules/classes/point"):new()
        point:load(pData)
        self.points[key] = point
    end

    self.id = data.id
    self.connectedID = data.connectedID
    self.station = data.station

    self.connections = getTrackConnections(self)
end

function track:save(path)
    local data = {}

    data.id = self.id
    data.connectedID = self.connectedID
    data.station = self.station
    data.points = {}
    for key, point in pairs(self.points) do
        data.points[key] = point:getData()
    end

    config.saveFile(path, data)
end

return track