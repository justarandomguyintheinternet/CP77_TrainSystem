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
	o.originalSpeed = stationSys.ts.settings.trainSpeed
	o.speed = 0
	o.pointIndex = 1
	o.routeDir = ""

	o.carName =  "Vehicle.v_sportbike3_brennan_apollo"
	o.carApp = "brennan_apollo_basic_burnt_v_2"
	o.carOffset = Vector4.new(0, 0, stationSys.ts.settings.tppOffset, 0)
	o.carLayer = 2010
	o.trainLayer = 2011
	o.carObject = nil
	o.trainObject = nil

	o.perspective = "tpp"
	o.camDist = stationSys.ts.settings.camDist
	o.allowSwitching = true
	o.currentSeat = stationSys.ts.settings.defaultSeat
	o.seats = {"seat_front_right", "seat_back_right", "seat_back_left", "seat_front_left"}
	o.radioStation = -1

	o.busObject = object:new(0)
	o.busOffset = Vector4.new(0, 0, 1.5, 0)
	o.busLayer = 2012

	o.playerMounted = false
	o.justArrived = false

	o.pos = Vector4.new(0, 0, 0, 0)
	o.rot = Quaternion.new(0.1, 0, 0, 0)

	o.ts = stationSys.ts
	o.stationSys = stationSys
	o.spawnStationID = nil

	o.audioTimer = nil

	self.__index = self
   	return setmetatable(o, self)
end

function train:spawn()
	local point = self.arrivalPath[#self.arrivalPath]
	self.carObject = object:new(self.carLayer)
	self.carObject.name = self.carName
	self.carObject.app = self.carApp

	self.carObject.pos = utils.addVector(point.pos, Vector4.new(0, 0, self.stationSys.currentStation.spawnOffset, 0))
	self.carObject.rot = point.rot

	self.trainObject = object:new(self.trainLayer, nil, "ent")
	self.trainObject.name = "Vehicle.av_public_train_b"
	self.trainObject.pos = utils.addVector(point.pos, Vector4.new(0, 0, self.stationSys.currentStation.spawnOffset, 0))
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
	local point = self.arrivalPath[#self.arrivalPath]
	local pos = utils.addVector(point.pos, Vector4.new(0, 0, -math.abs(self.stationSys.currentStation.spawnOffset*2), 0))
	self.busObject.rot = Game.GetCameraSystem():GetActiveCameraForward():ToRotation():ToQuat()
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
end

function train:startDrive(route)
	self.pointIndex = 1
	if route == "arrive" then
		self.activePath = self.arrivalPath
		self.driving = true
		self.speed = self.originalSpeed
		self.routeDir = "arrive"
	elseif route == "exit" then
		self.activePath = self.exitPath
		self.driving = true
		self.speed = 0
		self:handlePoint(self.activePath[1])
		self.routeDir = "exit"
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

function train:getRemainingExitLength()
	local length = 0
	length = length + utils.distanceVector(self.pos, self.activePath[self.pointIndex + 1].pos)
	for i = self.pointIndex + 2, #self.activePath, 1 do
		if not (self.activePath[i].dir == "next" and self.activePath[i].unloadStation.next or self.activePath[i].dir == "last" and self.activePath[i].unloadStation.last) then
			length = length + utils.distanceVector(self.activePath[i].pos, self.activePath[i - 1].pos)
		else
			break
		end
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
		if self:getDoneLength() < 25 and self.routeDir == "exit" then
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

			local newEuler = utils.calcDeltaEuler(self.activePath[self.pointIndex + 1].rot:ToEulerAngles(), self.rot:ToEulerAngles())
			self.rot = (utils.addEuler(utils.multEuler(newEuler, factor), self.rot:ToEulerAngles())):ToQuat()
		else
			local todo = self.speed * deltaTime
			while todo > 0 do
				--print("todo bigger 0" , todo)
				if (self.pointIndex + 1 > #self.activePath) then
					todo = 0
					self.justArrived = true
					self.driving = false
				elseif (utils.distanceVector(self.pos, self.activePath[self.pointIndex + 1].pos) < todo) then
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
						--print(math.abs(GetSingleton('Quaternion'):ToEulerAngles(self.rot).yaw - GetSingleton('Quaternion'):ToEulerAngles(self.activePath[self.pointIndex + 1].rot).yaw), "diff yaw")
						if math.abs(self.rot:ToEulerAngles().yaw - self.activePath[self.pointIndex + 1].rot:ToEulerAngles().yaw) > 300 then
							self.rot = self.activePath[self.pointIndex].rot
						end
					end
					--print("got over, new todo ", todo, "new p index ", self.pointIndex)
				else
					local dist = utils.distanceVector(self.pos, self.activePath[self.pointIndex + 1].pos) -- How much the total would been
					local factor = todo / dist -- How much percent of the dist should be done
					local dirVector = utils.subVector(self.activePath[self.pointIndex + 1].pos, self.pos)
					self.pos = utils.addVector(utils.multVector(dirVector, factor), self.pos)

					local newEuler = utils.calcDeltaEuler(self.activePath[self.pointIndex + 1].rot:ToEulerAngles(), self.rot:ToEulerAngles())
					self.rot = (utils.addEuler(utils.multEuler(newEuler, factor), self.rot:ToEulerAngles())):ToQuat()
					todo = 0
				end
			end
		end

		if self.justArrived and self.playerMounted then -- Once new station is reached, despawn the previous one
			if self.stationSys.stations[self.stationSys.previousStationID] then
				self.stationSys.stations[self.stationSys.previousStationID]:despawn()
			end
		end
		--print(self.activePath[self.pointIndex].rot:ToEulerAngles(), self.rot:ToEulerAngles())
	end

	if self.playerMounted then
		if self.ts.input.toggleCam and not self.ts.settings.tppOnly then
			self.ts.input.toggleCam = false
			if self.perspective == "tpp" and self.busObject.spawned then
				utils.unmount()
				utils.mount(self.busObject.entID, self.seats[self.currentSeat])
				self.perspective = "fpp"
				Game.GetPlayer():GetFPPCameraComponent():SetLocalPosition(Vector4.new(0,0,0,0))
				self.ts.input.down = false
				self.ts.input.up = false

				Cron.After(0.1, function()
					local set = self.ts.observers.radioIndex ~= -1
					vehRadioEvent = VehicleRadioEvent.new();    vehRadioEvent.toggle = false;    vehRadioEvent.setStation = set;    vehRadioEvent.station = self.ts.observers.radioIndex;    GetPlayer():QueueEventForEntityID(GetMountedVehicle(GetPlayer()):GetEntityID(), vehRadioEvent)
				end)
			else
				if self.currentSeat ~= 4 then
					utils.unmount()
					utils.mount(self.carObject.entID, "seat_front_left")
					self.perspective = "tpp"
					Game.GetPlayer():GetFPPCameraComponent():SetLocalPosition(Vector4.new(0,-self.camDist,0,0))

					Cron.After(0.1, function()
						utils.setRadioStation(ts.stationSys.activeTrain.carObject.entity, self.ts.observers.radioIndex)
					end)
				else
					Game.GetPlayer():SetWarningMessage("Can't switch when in this seat!")
				end
			end
		end

		if self.perspective == "fpp" then
			if self.ts.input.down then
				self.ts.input.down = false
				if self.ts.observers.radioPopupActive then return end

				self.currentSeat = self.currentSeat + 1
				if self.currentSeat > 4 then self.currentSeat = 1 end
				utils.unmount()
				utils.mount(self.busObject.entID, self.seats[self.currentSeat])

				Cron.After(0.1, function()
					local set = self.ts.observers.radioIndex ~= -1
					vehRadioEvent = VehicleRadioEvent.new();    vehRadioEvent.toggle = false;    vehRadioEvent.setStation = set;    vehRadioEvent.station = self.ts.observers.radioIndex;    GetPlayer():QueueEventForEntityID(GetMountedVehicle(GetPlayer()):GetEntityID(), vehRadioEvent)
				end)
			end
			if self.ts.input.up then
				self.ts.input.up = false
				if self.ts.observers.radioPopupActive then return end

				self.currentSeat = self.currentSeat - 1
				if self.currentSeat < 1 then self.currentSeat = 4 end
				utils.unmount()
				utils.mount(self.busObject.entID, self.seats[self.currentSeat])

				Cron.After(0.1, function()
					local set = self.ts.observers.radioIndex ~= -1
					vehRadioEvent = VehicleRadioEvent.new();    vehRadioEvent.toggle = false;    vehRadioEvent.setStation = set;    vehRadioEvent.station = self.ts.observers.radioIndex;    GetPlayer():QueueEventForEntityID(GetMountedVehicle(GetPlayer()):GetEntityID(), vehRadioEvent)
				end)
			end
		end
	end

	if self.carObject.spawned then
		self:updateLocation("car")
		self.carObject:update()
		self.carObject.entity:FindComponentByName("Chassis"):Toggle(false)
	end
	if self.trainObject.spawned then
		self:updateLocation("train")
		self.trainObject:update()
		self.trainObject.entity:FindComponentByName("Chassis"):Toggle(false)
	end
	if self.busObject.spawned then
		self:updateLocation("bus")
		self.busObject:update()
		self.busObject.entity:FindComponentByName("Chassis"):Toggle(false)
	end

	if not self.playerMounted then Game.GetPreventionSpawnSystem():RequestDespawnPreventionLevel(self.busLayer) end
	self:updateCam()
	self:handleAudio()
end

function train:updateLocation(obj)
	if obj == "car" then
		if self.perspective == "tpp" then
			self.carOffset = Vector4.new(0, 0, self.ts.settings.tppOffset, 0)
			self.carObject.pos = utils.addVector(self.pos, self.carOffset)
			self.carObject.rot = self.rot
		else
			self.carObject.pos = utils.subVector(self.pos, Vector4.new(0, 0, 24, 0))
		end
	elseif obj == "train" then
		if self.perspective == "tpp" then
			self.trainObject.pos = self.pos
			self.trainObject.rot = self.rot
		else
			self.trainObject.pos = utils.subVector(self.pos, Vector4.new(0, 0, 24, 0))
		end
	else
		if self.perspective == "tpp" then
			local pos = Game.GetPlayer():GetWorldPosition()
			pos.x = pos.x - Game.GetCameraSystem():GetActiveCameraForward().x * (self.camDist + 26)
			pos.y = pos.y - Game.GetCameraSystem():GetActiveCameraForward().y * (self.camDist + 26)
			pos.z = pos.z - Game.GetCameraSystem():GetActiveCameraForward().z * (self.camDist + 26)
			self.busObject.pos = pos
		else
			self.busObject.pos = utils.addVector(self.pos, self.busOffset)
			self.busObject.rot = self.rot
		end
	end
end

function train:handlePoint(point)
	if self.pointIndex == 1 and self.playerMounted and self.speed == 0 then -- Spawn next station when the driving starts with player mounted, speed not 0 makes sure it only gets called once
		self.stationSys.previousStationID = self.stationSys.currentStation.id
		self.stationSys.currentStation = self.stationSys.stations[self.targetID]
		self.stationSys.currentStation:spawn()
	end

	if point.dir == "next" and point.unloadStation.next or point.dir == "last" and point.unloadStation.last then -- No player mounted, new arrival
		if not self.playerMounted then
			self.driving = false
			self.pos = utils.subVector(self.stationSys.currentStation.center, Vector4.new(0, 0, 45, 0))
			Cron.After(2.0, function()
				self.stationSys:requestNewTrain()
			end)
		end
	end
end

function train:updateCam()
	if self.playerMounted then

		Game.GetPlayer():GetFPPCameraComponent().pitchMax = 80
		Game.GetPlayer():GetFPPCameraComponent().pitchMin = -80
		Game.GetPlayer():GetFPPCameraComponent().yawMaxRight = -360
		Game.GetPlayer():GetFPPCameraComponent().yawMaxLeft = 360

		if self.perspective == "tpp" then
			utils.switchCarCam("TPPFar")
			Game.GetPlayer():GetFPPCameraComponent():SetLocalPosition(Vector4.new(0,-self.camDist,0,0))
		else
			utils.switchCarCam("FPP")
			GetPlayer():GetFPPCameraComponent():SetLocalPosition(Vector4.new(0,0,0.2,0))
		end
	end
end

function train:handleAudio()
	if self.audioTimer == nil then
		if not self.trainObject.entity then return end
		utils.stopAudio(self.trainObject.entity, "v_metro_default_traffic_01_start")
		utils.playAudio(self.trainObject.entity, "v_metro_default_traffic_01_start")

		self.audioTimer = Cron.Every(20, function ()
			utils.stopAudio(self.trainObject.entity, "v_metro_default_traffic_01_start")
			utils.playAudio(self.trainObject.entity, "v_metro_default_traffic_01_start")
		end)
	end
end

function train:mount()
	self.perspective = "tpp"
	self.currentSeat = self.ts.settings.defaultSeat
	self.ts.input.down = false
	self.ts.input.up = false
	Cron.After(0.5, function ()
		if self.ts.settings.tppOnly then return end
		self:spawnBus()
	end)
	self.playerMounted = true
	utils.mount(self.carObject.entID, "seat_front_left")
	utils.switchCarCam("TPPFar")
	Game.GetPlayer():GetFPPCameraComponent():SetLocalPosition(Vector4.new(0,-self.camDist,0,0))
	Game.ApplyEffectOnPlayer("GameplayRestriction.NoDriving")

	Cron.After(0.1, function()
		utils.setRadioStation(ts.stationSys.activeTrain.carObject.entity, self.ts.observers.radioIndex)
	end)

	Cron.After(0.4, function ()
		if self.ts.settings.noHudTrain then utils.toggleHUD(false) end
	end)
end

function train:unmount()
	StatusEffectHelper.RemoveStatusEffect(GetPlayer(), "GameplayRestriction.NoDriving")
	GetPlayer():QueueEvent(vehicleCameraResetEvent.new())

	self.perspective = "tpp"
	self.playerMounted = false
	Game.GetPlayer():GetFPPCameraComponent():SetLocalPosition(Vector4.new(0,0,0,0))
	utils.unmount()
	self.busObject:despawn()

	local evt = DeleteInputHintBySourceEvent.new()
	evt.source = "turret"
	evt.targetHintContainer = "GameplayInputHelper"
	Game.GetUISystem():QueueEvent(evt)

	local evt = DeleteInputHintBySourceEvent.new()
	evt.source = "Debug"
	evt.targetHintContainer = "GameplayInputHelper"
	Game.GetUISystem():QueueEvent(evt)

	local evt = DeleteInputHintBySourceEvent.new()
	evt.source = "evcHints"
	evt.targetHintContainer = "GameplayInputHelper"
	Game.GetUISystem():QueueEvent(evt)

	utils.toggleHUD(true)
end

return train