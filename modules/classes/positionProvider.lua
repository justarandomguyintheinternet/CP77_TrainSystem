local utils = require("modules/utils/utils")

interpolator = {}

function interpolator:new()
	local o = {}

    o.active = false
    o.points = {}
    o.progress = 0
    o.multiplier = 0 -- Speed normalized
    o.interpolationFunction = nil

    -- Those two get set with setOffsets
    o.metroLength = 0 -- Measured in 0-1
    o.offset = 0 -- Measured in 0-1

    o.accelerationDistance = 200 -- Used for smoothStartEnd
    o.speed = 16
    o.nonNormalizedSpeedDivisor = 250 -- Used for the constant duration of e.g. arrival paths, lower means faster

    o.callbacks = {}

	self.__index = self
   	return setmetatable(o, self)
end

-- https://www.desmos.com/calculator/qdqi9mgvts
local function smoothStartEnd(x, smoothDistance)
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

-- https://www.desmos.com/calculator/q57lrplhal
local function fastStartSmoothEnd(x, slope)
    local offset = - (math.pow(slope, 4 / 6) / slope)

    return slope * math.pow((x + offset), 3) + 1
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
    if progress ~= progress then return a end

    local pos = utils.addVector(a.pos, utils.multVector(utils.subVector(b.pos, a.pos), progress))

    local aRot = a.rot:ToEulerAngles()
    local bRot = b.rot:ToEulerAngles()
    local yawDiff = bRot.yaw - aRot.yaw
    local yawDiffAbs = 180 - math.abs(bRot.yaw) + 180 - math.abs(aRot.yaw)

    if yawDiffAbs < math.abs(yawDiff) then -- Go over 180
        if bRot.yaw > aRot.yaw then
            yawDiff = - yawDiffAbs
        else
            yawDiff = yawDiffAbs
        end
    end

    local rot = utils.addEuler(a.rot:ToEulerAngles(), EulerAngles.new(0, (bRot.pitch - aRot.pitch) * progress, yawDiff * progress))

    local point = require("modules/classes/point"):new()
    point.pos = pos
    point.rot = rot:ToQuat()

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

--- Get the multiplied speed, normalized meaning the longer the path, the longer it takes. Non normalized will always take the same time to complete, e.g. for arrival
---@param normalized boolean
---@return number
function interpolator:getNormalizedSpeed(normalized)
    -- For the arrival paths, always the same time needed, no matter the distance
    if not normalized and not (getPathLength(self.points) < 150) then
        return self.speed / self.nonNormalizedSpeedDivisor
    else
        -- Normalized, so that it takes proportionally long, also do this for short paths
        return (1 / getPathLength(self.points)) * self.speed
    end
end

--- Functions should be called in the following order:
--- 1) setupXXX(), e.g. setupArrival for an arrival path
--- 2) setOffsets(), buffers the normalized offsets
--- 3) start(), buffers the optionally normalized speed and actually starts off the interpolator
--- 4) update()
--- 5) getCarriagePosition() to retrieve the point of a carriage, also checks for any callbacks

--- Sets up the interpolator to arrive from a path, splitting it etc. Distance is distance of path that should be driven
---@param path table
---@param distance number
function interpolator:setupArrival(path, distance)
    distance = math.min(getPathLength(path), distance) -- Cap distance to length of path
    local _, split = self:splitPathByProgress(path, 1 - self:getProgressByDistance(path, distance))

    self.points = split
    self.interpolationFunction = function (progress)
        return fastStartSmoothEnd(progress, 1)
    end
end

function interpolator:setupExit(path, flip)
    if not flip then
        local _, split = self:splitPathByProgress(self.points, 1 - self.metroLength) -- Not yet done distance of previous track
        self.points = utils.join(split, path)

        utils.bufferPathDistance(self.points)
    else
        self.points = path
    end

    self.interpolationFunction = function (progress)
        return smoothStartEnd(progress, self.accelerationDistance / getPathLength(self.points))
    end
end

--- Sets the offsets for the amount of carts, needs to be called after path has been set
---@param carts integer
---@param offset number
function interpolator:setOffsets(carts, offset)
    if #self.points == 0 then return end

    self.offset = offset / getPathLength(self.points)
    self.metroLength = (carts - 1) * self.offset
end

function interpolator:start(speedNormalized)
    self.progress = 0
    self.active = true
    self.multiplier = self:getNormalizedSpeed(speedNormalized)
end

function interpolator:update(deltaTime)
    if not self.active then return end
    self.progress = self.progress + deltaTime * self.multiplier

    if self.progress >= 1 then
        self.progress = 1
        self.active = false
    end
end

--- Registers a single use callback that gets triggered when the specified progress along the track / Y (Not the internal progress) has been reached
---@param progress any
---@param callback any
function interpolator:registerProgressCallback(progress, callback)
    local data = {
        index = utils.getNextFreeIndex(self.callbacks),
        fn = callback,
        trigger = "progress",
        triggerValue = progress
    }

    self.callbacks[data.index] = data
end

--- Registers a single use callback that gets triggered when the specified distance has been reached
function interpolator:registerDistanceCallback(distance, callback)
    local data = {
        index = utils.getNextFreeIndex(self.callbacks),
        fn = callback,
        trigger = "distance",
        triggerValue = distance
    }

    self.callbacks[data.index] = data
end

--- Checks and fires any callback that should be fired
---@param y number
---@param distance number
function interpolator:checkCallbacks(y, distance)
    for key, data in pairs(self.callbacks) do
        if data.trigger == "progress" then
            if y >= data.triggerValue then
                data.fn()
                self.callbacks[key] = nil
            end
        elseif data.trigger == "distance" then
            if distance >= data.triggerValue then
                data.fn()
                self.callbacks[key] = nil
            end
        end
    end
end

--- Returns the finalized point along the path as well as the 0-1 progress, based on the carriage index. Uses the interpolationFunction which has been set previously.
---@param index number
---@return table
---@return number
function interpolator:getCarriagePosition(index)
    local y = self.interpolationFunction(self.progress)

    if y >= 1 then
        y = 1
        self.active = false
        self.progress = 1
    end

    local offset = self.offset * (math.floor(self.metroLength / self.offset) + 1 - index)
    local t = y * (1 - self.metroLength) + offset
    local point, _ = getPointByProgress(self.points, t)

    return point, t
end

return interpolator