local utils = require("modules/utils/utils")

interpolator = {}

function interpolator:new()
	local o = {}

    o.active = false
    o.points = {}
    o.progress = 0
    o.multiplier = 0

    o.metroLength = 0 -- Measured in 0-1
    o.offset = 0 -- Measured in 0-1

    o.accelerationDistance = 200
    o.speed = 16

	self.__index = self
   	return setmetatable(o, self)
end

-- https://www.desmos.com/calculator/qdqi9mgvts
function interpolator:smoothStartEnd(x, smoothDistance)
    smoothDistance = math.min(smoothDistance, 0.5)
    x = math.min(x, 1)

    local f = 1 / (1 - smoothDistance) -- Slope of middle piece
    local t = 1 / (2 * smoothDistance * (1 - smoothDistance)) -- Slope of quadratic parts

    if x < smoothDistance then
        return t * math.pow(x, 2)
    elseif x < (1 - smoothDistance) then
        return (f * x) - (0.5 * f) + 0.5
    else
        return (-t * math.pow((x - 1), 2)) + 1
    end
end

--- Returns the buffered length of a path
---@param points table
---@return integer
local function getPathLength(points)
    if #points == 0 then return 0 end
    return points[#points].distance
end

--- Returns a point in between other points, by 0-1 progress value
---@param a table
---@param b table
---@param progress number
---@return table
local function tweenPoint(a, b, progress)
    local pos = utils.addVector(a.pos, utils.multVector(utils.subVector(b.pos, a.pos), progress))
    local rot = utils.addQuat(a.rot, utils.multQuat(utils.subQuat(b.rot, a.rot), progress))

    local point = require("modules/classes/point"):new()
    point.pos = pos
    point.rot = rot

    return point
end

--- Returns the point for the given progress, as well as index of the closests (Below) point in the table
---@param points table
---@param progress number
---@return table
---@return integer
local function getPointByProgress(points, progress)
    local distance = getPathLength(points) * progress

    -- Could optimize this ig
    local closestIndex = 1
    while points[closestIndex + 1].distance < distance do
        closestIndex = closestIndex + 1
    end

    -- Create point for missing distance
    local missingDistance = distance - points[closestIndex].distance
    local tweenProgress = missingDistance / points[closestIndex].pos:Distance(points[closestIndex + 1].pos)
    local point = tweenPoint(points[closestIndex], points[closestIndex + 1], tweenProgress)
    point.distance = distance

    return point, closestIndex
end

function interpolator:update(deltaTime)
    -- if started
    if not self.active then return end
    self.progress = self.progress + deltaTime * self.multiplier

    if self.progress >= 1 then
        self.active = false
    end
end

function interpolator:start()
    self.progress = 0
    self.multiplier = (1 / getPathLength(self.points)) * self.speed
    self.active = true
end

function interpolator:loadMainPath(points)
    -- cache them
    -- should get list of combined points
end

function interpolator:loadBufferedPath(points)

end

-- Returns the points after the first offset, i.e. the part of the track that must be remembered for the next time
function interpolator:getSharedPath()
    -- get all the path in front of the last offset value
end

-- WARNING : WARNING : WARNING : WARNING : WARNING : WARNING : WARNING --
-- bufferPathDistance() modifies original table's distance values
-- THIS MIGHT CAUSE ISSUES, BEWARE OF THIS
-- ALWAYS REBUFFER, IF IN DOUBT

--- Split the given path into a lower and upper section, end point of lower and start of upper are the same point
---@param points table
---@param progress number
---@return table, table
---@return nil, nil
function interpolator:splitPathByProgress(points, progress)
    if #points <= 1 then return nil, nil end
    if progress == 1 then return points, {} end

    local split = {}

    local point, closest = getPointByProgress(points, progress)

    for i = 1, closest do
        table.insert(split, points[i])
    end
    table.insert(split, point)

    local upperHalf = {point}
    for i = closest + 1, #points do
        table.insert(upperHalf, points[i])
    end
    utils.bufferPathDistance(upperHalf)

    return split, upperHalf
end

-- Returns a value from 0-1, given a distance that should be walked along an array of points
---@param points table
---@param distance number
---@return number
function interpolator:getProgressByDistance(points, distance)
	distance = math.min(distance, points[#points].distance)
	return distance / points[#points].distance
end

--- Sets the offsets for the amount of carts, needs to be called after path has been set
---@param carts integer
---@param offset number
function interpolator:setOffsets(carts, offset)
    if #self.points == 0 then return end

    self.offset = offset / getPathLength(self.points)
    self.metroLength = (carts - 1) * self.offset
end

--- Sets up the interpolator to arrive from a path, splitting it etc. Distance is distance of path that should be driven
---@param path table
---@param distance number
function interpolator:setupArrival(path, distance)
    distance = math.min(getPathLength(path), distance) -- Cap distance to length of path
    local _, split = self:splitPathByProgress(path, 1 - self:getProgressByDistance(path, distance))

    self.points = split
end

--- Sets up the interpolator to drive the path, using the previously used path to determine the shared part
---@param path table
function interpolator:setupDrive(path)

end

function interpolator:getCarriagePosition(index)
    local offset = self.offset * (math.floor(self.metroLength / self.offset) + 1 - index)
    local t = self:smoothStartEnd(self.progress, self.accelerationDistance / getPathLength(self.points)) * (1 - self.metroLength) + offset
    local point, _ = getPointByProgress(self.points, t)

    return point
end

return interpolator