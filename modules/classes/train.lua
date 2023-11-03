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
	o.path = {}
	o.carriages = {}

	self.__index = self
   	return setmetatable(o, self)
end

function train:spawn(spawnPoint)
	if self.spawned then return end

	self.spawned = true

	for i = 1, self.numCarriages do
		self.carriages[i] = require("modules/classes/carriage"):new(self)
		self.carriages[i]:spawn(spawnPoint)
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
	return false
end

function train:startArrival(station, previousLine)
	local lines = self.routingSystem:getLines(station)
	local line = lines[self.routingSystem:getNextLineIndex(previousLine, station)]

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

	self.path = self.interpolator.points

	print("Start metro arrival: ", self.activeLine.previousStationID, self.activeLine.nextStationID, line.name, line.towards, #path)

	-- figure out arrival path
	-- path is always: LineID + NextStationID + PreviousStationID
	-- start arrival drive, with custom interpolator for faster arrival
	-- when drive is done, check line + nextID to figure out what path to use next
		-- check if line is also line of new station
		-- if yes continue using that line
		-- otherwise load new reverse line? aka next line?
	-- load path again, leave
	-- when distance done and not player:
		-- use interpolator
		-- wait for distance
		-- use lineID + prevID to figure out next

	-- whenever route is done / station arrived:
		-- buffer not yet done path, and t values?
end

function train:arrivalDone()
	local nextID = self.routingSystem:getNextStationID(self.activeLine.data, self.activeLine.nextStationID)
	print("Done driving, next stationID: ", nextID, self.activeLine.data.towards)
end

function train:activateDrive()

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
	-- self:updateEntity()
	-- self:updateCam()
	-- self:handleAudio()
	if self.interpolator and self.interpolator.active then
		self.interpolator:update(deltaTime)
	end

	for key, cart in pairs(self.carriages) do
		cart:setPosition(self.interpolator:getCarriagePosition(key))
	end
end

function train:updateEntity()

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