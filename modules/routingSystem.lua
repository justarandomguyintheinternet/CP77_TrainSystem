local utils = require("modules/utils/utils")

routingSystem = {}

function routingSystem:new()
	local o = {}

	o.tracks = {}

	self.__index = self
   	return setmetatable(o, self)
end

function routingSystem:load()
	for _, file in pairs(dir("data/tracks")) do
        if file.name:match("^.+(%..+)$") == ".json" then
            local track = require("modules/classes/track"):new()
            track:load("data/tracks/" .. file.name)
            self.tracks[track.id] = track
        end
    end

	self:handleActOne()
end

function routingSystem:handleActOne()
	local hasSentJackie = not (Game.GetQuestsSystem():GetFact("q005_jackie_to_hospital") == 0 and Game.GetQuestsSystem():GetFact("q005_jackie_to_mama") == 0 and Game.GetQuestsSystem():GetFact("q005_jackie_stay_notell") == 0)
	local q101Done = Game.GetQuestsSystem():GetFactStr('q101_done') == 1
	local sideContentUnlocked = Game.GetQuestsSystem():GetFactStr('q101_enable_side_content') == 1

	if hasSentJackie or q101Done or sideContentUnlocked or self.ts.settings.unlockAllTracks then return end

	-- TODO: Change this to modify lines staion information, hardcoded
end

-- Checks if the id is in the tracks front connections
---@param track table
---@param id number
---@return boolean
local function isInFront(track, id)
	return id == track.connectedID.first.front or id == track.connectedID.second.front
end

-- Checks if the id is in the tracks back connections
---@param track table
---@param id number
---@return boolean
local function isInBack(track, id)
	return id == track.connectedID.first.back or id == track.connectedID.second.back
end

-- Returns the direction that the track is being walked along, given the previous track id
---@param track table
---@param previous number
---@return "forward"|"backward"
local function getDirection(track, previous)
	if isInBack(track, previous) then
		return "backward"
	else
		return "forward"
	end
end

-- Is the connecting track in the same direction **as we are coming from**, e.g. in front and we are walking front to back => Is same direction
---@param track table
---@param connection number
---@param previous number
local function isConnectionSameDirection(track, connection, previous)
	if isInFront(track, connection) and getDirection(track, previous) == "forward" then
		return true
	elseif isInBack(track, connection) and getDirection(track, previous) == "backwards" then
		return true
	end
	return false
end

--- Reverses a given table of points, both in order and rotation per point
---@param points any
---@return table
local function reversePoints(points)
	local reversed = {}

	for i = #points, 1, -1 do
		table.insert(reversed, utils.reversePoint(path.points[i]))
	end

	return reversed
end

--- Assuming the target station is on this track, it will return the points on this track to get to that station, in respect to the direction of travel
---@param track table
---@param direction string
---@param target number
---@return table
local function getLastMile(track, direction, target)
	if track.station.front == target and direction == "forward" then
		return {track.points[1]}
	elseif track.station.front == target and direction == "backwards" then
		return reversePoints(track.points)
	elseif track.station.back == target and direction == "forward" then
		return track.points
	elseif track.station.back == target and direction == "backwards" then
		return reversePoints({track.point[#track.point]})
	end
	return {}
end

--- Returns the track on which the specified station sits
---@param station number
---@return table
function routingSystem:getTrackByStationID(id)
	for _, track in pairs(self.tracks) do
		if track:hasStation(id) then
			return track
		end
	end
	return {}
end

--- DFS function to search for the specified target ID on the track, if found return the lastMile, otherwise check on next two tracks and if any of those return something merge their output with the current tracks points
---@param track table
---@param previous number
---@param target number
function routingSystem:dfs(track, previous, target)
	local path = {} -- Used in case that one the tracks children return something

	if track == nil then
		return path
	end

	if track:hasStation(target) then
		return getLastMile(track, getDirection(track, previous), target) -- Correct Station found somewhere on track, terminate
	end

	if track:hasAnyStation() then -- Station, but not the target one
		return path -- Return empty path, shows that this is a dead end
	end

	for connection in pairs(track.connections) do
		if not isConnectionSameDirection(track, connection, previous) and connection ~= -1 then -- Dont go back the same way we came from
			local result = self:dfs(self.tracks[connection], track.id, target)

			if #result ~= 0 then -- Found some path when going that connection
				if getDirection(track, previous) == "backward" then
					return utils.join(reversePoints(track.points), result)
				end
				return utils.join(track.points, result)
			end
		end
	end

	return path
end

--- Returns the table of points that leads from the origin station's id to the target station
---@param originID any
---@param target any
function routingSystem:findPath(originID, target)
	local track = self:getTrackByStationID(originID)

	if track.station.front == target then
		return getLastMile(track, "backward", target)
	end
	if track.station.back == target then
		return getLastMile(track, "forward", target)
	end

	-- Found at the back of this track
	local firstBack = self:dfs(self.tracks[track.connectedID.first.back], track.id, target)
	if #firstBack ~= 0 then
		-- Since it is in the back, we would go backwards along this track to find the origin station. Then reverse the points for this track, as we basically use the getLastMile but reversed
		return utils.join(reversePoints(getLastMile(track, "backward", originID)), firstBack)
	end

	local secondBack = self:dfs(self.tracks[track.connectedID.second.back], track.id, target)
	if #secondBack ~= 0 then
		return utils.join(reversePoints(getLastMile(track, "backward", originID)), secondBack)
	end

	-- Found at the front of this track
	local firstFront = self:dfs(self.tracks[track.connectedID.first.front], track.id, target)
	if #firstFront ~= 0 then
		return utils.join(reversePoints(getLastMile(track, "forward", originID)), firstFront)
	end

	local secondFront = self:dfs(self.tracks[track.connectedID.second.front], track.id, target)
	if #secondFront ~= 0 then
		return utils.join(reversePoints(getLastMile(track, "forward", originID)), secondFront)
	end
end

-- Returns a value from 0-1, given a distance that should be walked along an array of points
---@param points table
---@param distance number
---@return number
function routingSystem:getValueByDistance(points, distance)
	local length = 0
	for i = 1, #points.length - 1 do
		length = length + points[i].pos:Distance(points[i + 1].pos)
	end

	distance = math.min(distance, length)
	return distance / length
end

return routingSystem