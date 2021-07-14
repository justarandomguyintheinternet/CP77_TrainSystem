local object = require("modules/classes/object")
local utils = require("modules/utils/utils")
local Cron = require("modules/utils/Cron")

train = {}

function train:new(stationSys)
	local o = {}

	o.arrivalPath = {}
	o.exitPath = {}
	o.activePath = {}
	o.targetID = nil
	o.driving = false
	o.originalSpeed = 45
	o.speed = 0
	o.pointIndex = 1

	o.carName =  "Vehicle.cs_savable_makigai_maimai" --"Vehicle.v_sportbike3_brennan_apollo"--"Vehicle.cs_savable_mahir_mt28_coach" -- "Vehicle.cs_savable_makigai_maimai"
	o.carApp = "makigai_maimai__basic_burnt_01" --"brennan_apollo_basic_burnt_v_2"
	o.carOffset = Vector4.new(0, 0, 1.5, 0)
	o.carLayer = 2010
	o.trainLayer = 2011
	o.carObject = nil
	o.trainObject = nil

	o.perspective = "tpp"
	o.camDist = stationSys.ts.settings.camDist
	o.allowSwitching = true
	o.currentSeat = stationSys.ts.settings.defaultSeat

	o.busObject = object:new(0)
	o.busOffset = Vector4.new(0, 0, 0.5, 0)
	o.busLayer = 2012

	o.playerMounted = false
	o.justArrived = false
	o.requestBackupTrain = false

	o.pos = Vector4.new(0, 0, 0, 0)
	o.rot = Quaternion.new(0.1, 0, 0, 0)

	o.ts = stationSys.ts
	o.stationSys = stationSys
	o.spawnStationID = nil

	self.__index = self
   	return setmetatable(o, self)
end

function train:spawn()
	local point = self.arrivalPath[#self.arrivalPath]
	self.carObject = object:new(self.carLayer)
	self.carObject.name = self.carName
	self.carObject.app = self.carApp

	self.carObject.pos = point.pos
	self.carObject.rot = point.rot

	self.trainObject = object:new(self.trainLayer)
	self.trainObject.name = "Vehicle.av_public_train_b"
	self.trainObject.pos = point.pos
	self.trainObject.rot = point.rot

	point = self.arrivalPath[1]
	self.pos = point.pos
	self.rot = point.rot

	self.carObject:spawn()
	self.trainObject:spawn()
end

function train:spawnBus()
	self.busObject = object:new(self.busLayer)
	self.busObject.name = "Vehicle.cs_savable_mahir_mt28_coach"
	local pos = Game.GetPlayer():GetWorldPosition()
	pos.x = pos.x - Game.GetCameraSystem():GetActiveCameraForward().x * self.camDist + 5
	pos.y = pos.y - Game.GetCameraSystem():GetActiveCameraForward().y * self.camDist + 5
	pos.z = pos.z - Game.GetCameraSystem():GetActiveCameraForward().z * self.camDist + 5
	self.busObject.pos = pos
	self.busObject:spawn()
end

function train:despawn()
	if self.carObject ~= nil then
		self.carObject:despawn()
	end
	if self.trainObject ~= nil then
		self.trainObject:despawn()
	end
end

function train:loadRoute(route)
	self.pointIndex = 1
	self.arrivalPath = route.arrivalPath
	self.exitPath = route.exitPath
	self.targetID = route.targetID
	for k, p in pairs(self.exitPath) do
		print(k, GetSingleton('Quaternion'):ToEulerAngles(p.rot), "exitPath")
	end
	for k, p in pairs(self.arrivalPath) do
		print(k, GetSingleton('Quaternion'):ToEulerAngles(p.rot), "arrivalPath")
	end
end

function train:startDrive(route)
	self.pointIndex = 1
	if route == "arrive" then
		self.activePath = self.arrivalPath
		self.driving = true
		self.speed = self.originalSpeed
	else
		self.activePath = self.exitPath
		self.driving = true
		self:handlePoint(self.activePath[1])
		self.speed = 0
	end
	self.pos = self.activePath[1].pos
	self.rot = self.activePath[1].rot
end

function train:getRemainingLength()
	local length = 0
	length = length + utils.distanceVector(self.pos, self.activePath[self.pointIndex + 1].pos)
	for i = self.pointIndex + 2, #self.activePath, 1 do
		length = length + utils.distanceVector(self.activePath[i].pos, self.activePath[i - 1].pos)
	end
	return length
end

function train:getDoneLength()
	local length = 0
	length = length + utils.distanceVector(self.pos, self.activePath[self.pointIndex].pos)
	for i = self.pointIndex, 2, -1 do
		length = length + utils.distanceVector(self.activePath[i].pos, self.activePath[i - 1].pos)
	end
	return length
end

function train:update(deltaTime)
	if self.driving then
		--print("driving, pos", self.pos, "point index: ", self.pointIndex, "points: ", #self.activePath)
		if self:getDoneLength() < 25 then
			self.speed = self:getDoneLength() * 3 + 0.1--self.originalSpeed * ((self:getDoneLength() + 0.01 / 25))
			self.speed = math.min(self.speed, self.originalSpeed)
		end
		if self:getRemainingLength() < 25 then
			self.speed = self.originalSpeed * (self:getRemainingLength() / 25)
			self.speed = math.max(0.75, self.speed)
		end
		if utils.distanceVector(self.pos, self.activePath[self.pointIndex + 1].pos) > self.speed * deltaTime then
			--print("below next point")
			local todo = self.speed * deltaTime -- How much i want to do
			local dist = utils.distanceVector(self.pos, self.activePath[self.pointIndex + 1].pos) -- How much the total would been
			local factor = todo / dist -- How much percent of the dist should be done
			local dirVector = utils.subVector(self.activePath[self.pointIndex + 1].pos, self.pos)
			self.pos = utils.addVector(utils.multVector(dirVector, factor), self.pos)

			local newEuler = utils.calcDeltaEuler(GetSingleton('Quaternion'):ToEulerAngles(self.activePath[self.pointIndex + 1].rot), GetSingleton('Quaternion'):ToEulerAngles(self.rot))
			self.rot = GetSingleton('EulerAngles'):ToQuat(utils.addEuler(utils.multEuler(newEuler, factor), GetSingleton('Quaternion'):ToEulerAngles(self.rot)))
		else
			local todo = self.speed * deltaTime
			while todo > 0 do
				--print("todo bigger 0" , todo)
				if utils.distanceVector(self.pos, self.activePath[self.pointIndex + 1].pos) < todo then
					--print("would get over to next one, current point index", self.pointIndex)
					todo = todo - utils.distanceVector(self.pos, self.activePath[self.pointIndex + 1].pos)
					self.pos = self.activePath[self.pointIndex + 1].pos
					self.rot = self.activePath[self.pointIndex + 1].rot
					self:handlePoint(self.activePath[self.pointIndex + 1])
					self.pointIndex = self.pointIndex + 1
					if self.pointIndex == #self.activePath then
						self.justArrived = true
						self.driving = false
					else
						print(math.abs(GetSingleton('Quaternion'):ToEulerAngles(self.rot).yaw - GetSingleton('Quaternion'):ToEulerAngles(self.activePath[self.pointIndex + 1].rot).yaw), "diff yaw")
						if math.abs(GetSingleton('Quaternion'):ToEulerAngles(self.rot).yaw - GetSingleton('Quaternion'):ToEulerAngles(self.activePath[self.pointIndex + 1].rot).yaw) > 300 then
							self.rot = self.activePath[self.pointIndex + 1].rot
						end
					end
					--print("got over, new todo ", todo, "new p index ", self.pointIndex)
				else
					local dist = utils.distanceVector(self.pos, self.activePath[self.pointIndex + 1].pos) -- How much the total would been
					local factor = todo / dist -- How much percent of the dist should be done
					local dirVector = utils.subVector(self.activePath[self.pointIndex + 1].pos, self.pos)
					self.pos = utils.addVector(utils.multVector(dirVector, factor), self.pos)

					local newEuler = utils.calcDeltaEuler(GetSingleton('Quaternion'):ToEulerAngles(self.activePath[self.pointIndex + 1].rot), GetSingleton('Quaternion'):ToEulerAngles(self.rot))
					self.rot = GetSingleton('EulerAngles'):ToQuat(utils.addEuler(utils.multEuler(newEuler, factor), GetSingleton('Quaternion'):ToEulerAngles(self.rot)))
					todo = 0
				end
			end
		end
	end

	if self.playerMounted then
		if self.ts.input.toggleCam then
			self.ts.input.toggleCam = false
			if self.perspective == "tpp" and self.busObject.spawned then
				utils.unmount()
				utils.mount(self.busObject.entID, self.currentSeat)
				self.perspective = "fpp"
				Game.GetPlayer():GetFPPCameraComponent():SetLocalPosition(Vector4.new(0,0,0,0))
			else
				utils.unmount()
				utils.mount(self.carObject.entID, "seat_front_left")
				self.perspective = "tpp"
				Game.GetPlayer():GetFPPCameraComponent():SetLocalPosition(Vector4.new(0,-self.camDist,0,0))
			end
			print("Now switched to ", self.perspective)
		end
	end

	if self.carObject.spawned then
		self:updateLocation("car")
		self.carObject:update()
	end
	if self.trainObject.spawned then
		self:updateLocation("train")
		self.trainObject:update()
	end
	if self.busObject.spawned then
		self:updateLocation("bus")
		self.busObject:update()
	end
	print(self.busObject.spawned)
	if not self.playerMounted then Game.GetPreventionSpawnSystem():RequestDespawnPreventionLevel(self.busLayer) end
	self:updateCam()
end

function train:updateLocation(obj)
	if obj == "car" then
		if self.perspective == "tpp" then
			self.carObject.pos = utils.addVector(self.pos, self.carOffset)
			self.carObject.rot = self.rot
		else
			local pos = Game.GetPlayer():GetWorldPosition()
			pos.x = pos.x - Game.GetCameraSystem():GetActiveCameraForward().x * self.camDist / 3
			pos.y = pos.y - Game.GetCameraSystem():GetActiveCameraForward().y * self.camDist / 3
			pos.z = pos.z - Game.GetCameraSystem():GetActiveCameraForward().z * self.camDist / 3
			self.carObject.pos = pos
		end
	elseif obj == "train" then
		if self.perspective == "tpp" then
			self.trainObject.pos = self.pos
			self.trainObject.rot = self.rot
		else
			local pos = Game.GetPlayer():GetWorldPosition()
			pos.x = pos.x - Game.GetCameraSystem():GetActiveCameraForward().x * self.camDist / 3
			pos.y = pos.y - Game.GetCameraSystem():GetActiveCameraForward().y * self.camDist / 3
			pos.z = pos.z - Game.GetCameraSystem():GetActiveCameraForward().z * self.camDist / 3
			self.trainObject.pos = pos
		end
	else
		if self.perspective == "tpp" then
			local pos = Game.GetPlayer():GetWorldPosition()
			pos.x = pos.x - Game.GetCameraSystem():GetActiveCameraForward().x * self.camDist + 5
			pos.y = pos.y - Game.GetCameraSystem():GetActiveCameraForward().y * self.camDist + 5
			pos.z = pos.z - Game.GetCameraSystem():GetActiveCameraForward().z * self.camDist + 5
			self.busObject.pos = pos
		else
			self.busObject.pos = utils.addVector(self.pos, self.busOffset)
			self.busObject.rot = self.rot
		end
	end
end

function train:handlePoint(point)
	print(point.pos, point.loadStation.next, point.loadStation.last, point.unloadStation.next, point.unloadStation.last, point.dir)
	if point.dir == "next" and point.unloadStation.next or point.dir == "last" and point.unloadStation.last then -- Unload previous
		if self.playerMounted then
			if (self.stationSys.previousStationID ~= self.stationSys.currentStation.id) and (self.stationSys.previousStationID ~= nil) then
				self.stationSys.stations[self.stationSys.previousStationID]:despawn()
			else
				self.stationSys.currentStation:despawn()
				if self.stationSys.backUpTrain ~= nil then
					self.stationSys.backUpTrain:despawn()
					self.stationSys.backUpTrain = nil
				end
			end
			print("despawned previous station")
		else
			print("no player, back to arriving")
			self.driving = false
			self.stationSys:requestNewTrain()
		end
	end
	if ((point.dir == "next" and point.loadStation.next) or (point.dir == "last" and point.loadStation.last)) and self.playerMounted then -- Load next
		self.stationSys.previousStationID = self.stationSys.currentStation.id
		self.stationSys.currentStation = self.stationSys.stations[self.targetID]
		self.stationSys.currentStation:spawn()
		print("loading new station with id ", self.stationSys.currentStation.id)
		self.requestBackupTrain = true
	end
end

function train:spawnBackupTrain()
	if self.spawnStationID ~= self.stationSys.currentStation.id then
		self.stationSys.backUpTrain = object:new(2021)
		self.stationSys.backUpTrain.name = "Vehicle.av_public_train_b"
		self.stationSys.backUpTrain.pos = self.activePath[#self.activePath].pos
		self.stationSys.backUpTrain.rot = self.activePath[#self.activePath].rot
		self.stationSys.backUpTrain:spawn()
		Cron.Every(0.01, {tick = 0}, function(timer)
			if self.stationSys.backUpTrain.spawned then
				self.stationSys.backUpTrain.pos = utils.addVector(self.activePath[#self.activePath].pos, Vector4.new(0, 0, -50, 0))
				self.stationSys.backUpTrain:update()
				timer:Halt()
			end
		end)
		print("loaded backup train")
	end
end

function train:updateCam()
	if self.playerMounted then
		utils.switchCarCam("FPP")
		Game.GetPlayer():GetFPPCameraComponent().pitchMax = 80
		Game.GetPlayer():GetFPPCameraComponent().pitchMin = -80
		Game.GetPlayer():GetFPPCameraComponent().yawMaxRight = -360
		Game.GetPlayer():GetFPPCameraComponent().yawMaxLeft = 360
	end
end

function train:mount()
	self.perspective = "tpp"
	Cron.After(0.5, function ()
		self:spawnBus()
	end)
	self.playerMounted = true
	utils.mount(self.carObject.entID, "seat_front_left")
	utils.switchCarCam("FPP")
	Game.GetPlayer():GetFPPCameraComponent():SetLocalPosition(Vector4.new(0,-self.camDist,0,0))
end

function train:unmount()
	self.perspective = "tpp"
	self.playerMounted = false
	Game.GetPlayer():GetFPPCameraComponent():SetLocalPosition(Vector4.new(0,0,0,0))
	utils.unmount()
	self.busObject:despawn()
	if self.requestBackupTrain then -- Only spawn after unmount
		self.requestBackupTrain = false
		self:spawnBackupTrain()
	end
end

return train