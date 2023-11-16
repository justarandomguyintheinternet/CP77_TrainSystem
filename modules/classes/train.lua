local utils = require("modules/utils/utils")
local Cron = require("modules/utils/Cron")

train = {}

function train:new(stationSys)
	local o = {}

	o.routingSystem = stationSys.ts.routingSystem
	o.stationSys = stationSys
	o.numCarriages = 3
	o.offset = 10

	o.spawned = false

	o.activeLine = {}
	o.carriages = {}
	o.reverse = false

	self.__index = self
   	return setmetatable(o, self)
end

function train:spawn()
	if self.spawned then return end

	self.spawned = true

	for i = 1, self.numCarriages do
		self.carriages[i] = require("modules/classes/carriage"):new(self)
		self.carriages[i]:spawn(self.interpolator.points[1])
	end
end

function train:despawn()
	if not self.spawned then return end

	self.spawned = false

	for i = 1, self.numCarriages do
		self.carriages[i]:despawn()
	end

	self.carriages = {}
end

function train:playerBoarded()
	return self.carriages[2]:getEntity():GetWorldPosition():Distance(GetPlayer():GetWorldPosition()) < 15
end

function train:startArrival(station, previousLineID)
	local lines = self.routingSystem:getLines(station)
	local line = lines[self.routingSystem:getNextLineIndex(previousLineID, station)]

	self.activeLine = {
		data = line,
		nextStationID = station,
		previousStationID = self.routingSystem:getPreviousStationID(line, station)
	}

	self.interpolator = require("modules/classes/positionProvider"):new()

	local path = self.routingSystem:findPath(self.activeLine.previousStationID, station)

	self.interpolator:setupArrival(path, 5000)
	self.interpolator:setOffsets(self.numCarriages, self.offset)
	self.interpolator:start(false)

	self.interpolator:registerProgressCallback(1, function ()
		self:arrivalDone()
	end)
end

function train:arrivalDone()
	local currentStation = self.activeLine.nextStationID

	local flip = self.activeLine.data.stations[1] == currentStation or self.activeLine.data.stations[#self.activeLine.data.stations] == currentStation
	if flip then
		self.reverse = not self.reverse

		-- Since the previously used line wont be going through the end station, we need to use the new line going in the reverse direction
		if self.activeLine.data.towards == currentStation then
			local start = self.activeLine.data.stations[1]
			if start == currentStation then
				start = self.activeLine.data.stations[#self.activeLine.data.stations]
			end
			self.activeLine.data = self.routingSystem:getLineByStartEnd(currentStation, start)
		end
	end

	local nextID = self.routingSystem:getNextStationID(self.activeLine.data, currentStation)

	self.activeLine = {
		data = self.activeLine.data,
		nextStationID = nextID,
		previousStationID = currentStation
	}

	local path = self.routingSystem:findPath(self.activeLine.previousStationID, nextID)
	self.interpolator:setupExit(path, flip)
	self.interpolator:setOffsets(self.numCarriages, self.offset)
	self.interpolator.progress = 0

	Cron.After(1, function ()
		self.interpolator:start(true)

		-- TODO Change this to use station specific distances and hold time
		self.interpolator:registerDistanceCallback(45, function ()
			if not self:playerBoarded() then -- player not on board
				print("leaving, no player on board")
				self.interpolator:setInterpolationFunctionLeave()
				self.interpolator:registerProgressCallback(1, function ()
					self:startArrival(self.activeLine.previousStationID, self.activeLine.data.id)
				end)
			else
				self.interpolator:registerProgressCallback(1, function ()
					self:arrivalDone()
				end)
			end
		end)
	end)

	if flip then
		-- Reverse order, to reverse offsets and positions being calculated
		local flipped = {}
		for key, cart in pairs(self.carriages) do
			flipped[#self.carriages + 1 - key] = cart
		end
		self.carriages = flipped
	end
end

function train:getRemainingLength()
	local length = 0
	length = length + utils.distanceVector(self.pos, self.activePath[self.pointIndex + 1].pos)
	for i = self.pointIndex + 2, #self.activePath, 1 do
		length = length + utils.distanceVector(self.activePath[i].pos, self.activePath[i - 1].pos)
	end
	return length
end

function train:update(deltaTime)
	if self.interpolator and self.interpolator.active then
		self.interpolator:update(deltaTime)
	end

	for key, cart in pairs(self.carriages) do
		cart:setPosition(self.interpolator:getCarriagePosition(key), self.reverse)
	end

	-- Only trigger callbacks after having set all carriages positions, as callbacks might involve loading new track data
	local point, progress = self.interpolator:getCarriagePosition(1)
	self.interpolator:checkCallbacks(progress, point.distance)
end

function train:updateCam()
	if self.playerMounted then
		GetPlayer():GetFPPCameraComponent().pitchMax = 80
		GetPlayer():GetFPPCameraComponent().pitchMin = -80
		GetPlayer():GetFPPCameraComponent().yawMaxRight = -360
		GetPlayer():GetFPPCameraComponent().yawMaxLeft = 360

		if self.perspective == "tpp" then
			utils.switchCarCam("TPPFar")
			GetPlayer():GetFPPCameraComponent():SetLocalPosition(Vector4.new(0, 0, 0, 0))
		else
			utils.switchCarCam("FPP")
			GetPlayer():GetFPPCameraComponent():SetLocalPosition(Vector4.new(0, 0, 0.2, 0))
		end
	end
end

function train:handleAudio()

end

return train