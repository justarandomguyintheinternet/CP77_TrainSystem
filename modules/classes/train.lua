local utils = require("modules/utils/utils")
local Cron = require("modules/utils/Cron")

local busComponents = {"entrance_step", "v_mahir_mt28_coach__int01_window_strut_01", "interior_01", "seats", "window-console_right_04", "window-console_right_03", "window-console_right_02", "window-console_right_01", "window-console_left_01", "window-console_left_02", "window-console_left_03", "window-console_left_04", "SLIDING_WINDOW", "v_mahir_mt28_coach__ext01_body_01_shadow", "v_mahir_mt28_coach__int01_luggage_b_01", "v_mahir_mt28_coach__int01_luggage_a_01", "fx_cutout", "windowstatic_left_05", "windowstatic_left_right_05", "windowstatic_left_large_02", "windowstatic_right_01", "windowstatic_right_large_01", "windowstatic_right_large_02", "windowstatic_left_large_03", "windowstatic_left_03", "windowstatic_left_right_03", "windowstatic_left_large_01", "windowstatic_left_01", "windowstatic_left_right_02", "windowstatic_left_04", "windowstatic_left_02", "body_01", "windshield", "wipers_01", "body_lights_01", "position_lights_01", "license_plate", "windowstatic_right_4", "door", "cars_sport_fx", "ObjectCarrier", "fx_explosion", "AnimationController", "trunkBodyDisposalNpc", "trunkBodyDisposalPlayer", "VehicleAudio", "trunkBodyPickupNpc", "EngineAudioEmitter", "trunkBodyPickupPlayer", "scanning", "StatsComponent", "EffectAttachment", "StimBroadcaster", "vision", "AIComponent", "Weakspot", "entityStub", "entityStubPlacedProxy", "GeneralAudioEmitter", "CrowdMember", "TriggerActivator", "workspotMapper", "SignalHandler", "Targeting", "Inventory", "WheelAudioEmitterFL", "WheelAudioEmitterFR", "WheelAudioEmitterBL", "WheelAudioEmitterBR", "UI_slots", "influenceObstacle", "Repeller", "VehicleHoodEmitter", "VehicleTrunkEmitter"}
local alwaysOff = {"tire_01_bl_a_shadow", "tire_01_bl_b_shadow", "tire_01_br_a_shadow", "tire_01_br_b_shadow", "tire_01_fl_a_shadow", "tire_01_fl_b_shadow", "tire_01_fr_a_shadow", "tire_01_fr_b_shadow", "chasis", "body_shadow", "Chassis", "tire_01_bl_a", "wheel_01_bl_a", "tire_01_bl_b", "wheel_01_bl_b", "tire_01_br_a", "wheel_01_br_a", "wheel_01_br_b", "tire_01_br_b", "tire_01_fl_a", "wheel_01_fl_a", "wheel_01_fl_b", "tire_01_fl_b", "wheel_01_fr_a", "tire_01_fr_a", "wheel_01_fr_b", "tire_01_fr_b",}

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

	o.trainID = nil
	o.zAdjustment = 0.415

	o.perspective = "tpp"
	o.componentSwitchDelay = false
	o.camDist = stationSys.ts.settings.camDist
	o.allowSwitching = true
	o.currentSeat = stationSys.ts.settings.defaultSeat
	o.seats = {
		{-1.6, -0.25, -0.05},
		{-1.6, -1, -0.05},
		{-1.6, -1.9, -0.05},
		{-1.6, -2.75, -0.05},
		{-1.6, -3.65, -0.05},
		{-1.6, -4.55, -0.05},
		{-1.6, -5.45, -0.05},
		{-1.6, -6.55, -0.05},
		{0.0, -6.55, -0.05},
		{0.0, -5.45, -0.05},
		{0.0, -4.55, -0.05},
		{0.0, -3.65, -0.05},
		{0.0, -2.75, -0.05},
		{0.0, -1.9, -0.05},
		{0.0, -1, -0.05},
	}

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

function train:getEntity() -- Get train entity
	local object = Game.FindEntityByID(self.trainID)
	if not object then return end
	return object
end

function train:spawn()
	local point = self.arrivalPath[#self.arrivalPath]

	local spec = DynamicEntitySpec.new()

	spec.recordID = "Vehicle.train"
	spec.position = point.pos
	spec.orientation = point.rot
	spec.alwaysSpawned = true
	self.trainID = Game.GetDynamicEntitySystem():CreateEntity(spec)

	point = self.arrivalPath[1]
	self.pos = point.pos
	self.rot = point.rot
end

function train:despawn()
	if self:getEntity() ~= nil then
		utils.stopAudio(self:getEntity(), "v_metro_default_traffic_01_start")
		Cron.Halt(self.audioTimer)
		self.pos = utils.addVector(self.pos, Vector4.new(0, 0, 500, 0))
		self:updateEntity()
		Cron.After(0.75, function ()
			Game.GetDynamicEntitySystem():DeleteEntity(self.trainID)
		end)
	end
end
--Game.GetDynamicEntitySystem():CreateEntity(DynamicEntitySpec.new({recordID = "Vehicle.train", position = GetPlayer():GetWorldPosition()}))
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

	if self.playerMounted then -- Input handling
		if self.ts.input.toggleCam then -- Switch cam
			self.ts.input.toggleCam = false
			if self.perspective == "tpp" then
				self.componentSwitchDelay = true
				Cron.After(0.42, function()
					self.componentSwitchDelay = false
				end)
				self.perspective = "fpp"
				self.ts.input.down = false
				self.ts.input.up = false
			else
				self.componentSwitchDelay = false
				self.perspective = "tpp"
			end
		end

		if self.perspective == "fpp" then -- Switch seat
			if self.ts.input.down then
				self.ts.input.down = false
				if self.ts.observers.radioPopupActive then return end

				self.currentSeat = self.currentSeat + 1
				if self.currentSeat > #self.seats then self.currentSeat = 1 end
				self:setSeatPosition()
			end
			if self.ts.input.up then
				self.ts.input.up = false
				if self.ts.observers.radioPopupActive then return end

				self.currentSeat = self.currentSeat - 1
				if self.currentSeat < 1 then self.currentSeat = #self.seats end
				self:setSeatPosition()
			end
		end
	end

	self:updateEntity()
	self:updateCam()
	-- self:handleAudio()
end

function train:updateEntity()
	local entity = self:getEntity()
	if not entity then return end

	Game.GetTeleportationFacility():Teleport(entity, utils.addVector(self.pos, Vector4.new(0, 0, self.zAdjustment, 0)),  self.rot:ToEulerAngles())

	entity:TurnVehicleOn(true)
	entity:GetVehicleComponent():GetVehicleController():ToggleLights(true)

	if self.perspective == "tpp" then
		self:toggleBus(false, entity)
		self:toggleTrain(true, entity)
	else
		self:toggleBus(true, entity)
		self:toggleTrain(false, entity)
	end
end

function train:toggleBus(state, entity)
	for _, name in pairs(alwaysOff) do -- Never want these
		component = entity:FindComponentByName(name)
		if component then
			component:Toggle(false)
			if component:IsA("entIPlacedComponent") then
				component:SetLocalPosition(Vector4.new(0, 0, -35, 0))
			end
		end
	end

	if self.componentSwitchDelay then state = not state end

	for _, name in pairs(busComponents) do
		component = entity:FindComponentByName(name)
		if component then
			component:Toggle(state)
			if component:IsA("entIPlacedComponent") then
				if state then
					component:SetLocalPosition(Vector4.new(0, 0, 0, 0))
				else
					component:SetLocalPosition(Vector4.new(0, 0, -35, 0))
				end
			end
		end
	end
end

function train:toggleTrain(state, entity)
	if self.componentSwitchDelay then state = not state end

	local components = {"train_default", "train_e3"}

	if state then
		for _, name in pairs(components) do
			component = entity:FindComponentByName(name)
			if component then
				component:Toggle((self.ts.settings.blueTrain and name == "train_e3") or (not self.ts.settings.blueTrain and name == "train_default"))
				component:SetLocalPosition(Vector4.new(0, 0, 0, 0))
			end
		end
	else
		for _, name in pairs(components) do
			component = entity:FindComponentByName(name)
			if component then
				component:Toggle(false)
				component:SetLocalPosition(Vector4.new(0, 0, -35, 0))
			end
		end
	end
end

function train:setSeatPosition()
	local entity = self:getEntity()
	if not entity then return end
	local slots = entity:FindComponentByName("OccupantSlots").slots
	slots[2].relativePosition = Vector3.new(self.seats[self.currentSeat][1], self.seats[self.currentSeat][2], self.seats[self.currentSeat][3])
	entity:FindComponentByName("OccupantSlots").slots = slots
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
			self.pos = utils.subVector(self.stationSys.currentStation.center, Vector4.new(0, 0, 75, 0))
			Cron.After(2.0, function()
				self.stationSys:requestNewTrain()
			end)
		end
	end
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
	if self.audioTimer == nil then
		local entity = self:getEntity()
		if not entity then return end
		utils.stopAudio(entity, "v_metro_default_traffic_01_start")
		utils.playAudio(entity, "v_metro_default_traffic_01_start")

		self.audioTimer = Cron.Every(12, function ()
			local entity = self:getEntity()
			if not entity then return end
			utils.stopAudio(entity, "v_metro_default_traffic_01_start")
			utils.playAudio(entity, "v_metro_default_traffic_01_start")
		end)
	end
end

function train:calculateSeatIndex(setting)
	local value = 0
	if setting == 1 then
		value = 15
	elseif setting == 2 then
		value = 11
	elseif setting == 3 then
		value = 6
	elseif setting == 4 then
		value = 2
	end
	return value
end

function train:mount()
	self.perspective = "tpp"
	self.currentSeat = self:calculateSeatIndex(self.ts.settings.defaultSeat)
	self.ts.input.down = false
	self.ts.input.up = false

	self.playerMounted = true
	utils.mount(self:getEntity():GetEntityID(), "seat_front_right")
	utils.switchCarCam("TPPFar")
	utils.applyStatus("GameplayRestriction.NoDriving")
	self:setSeatPosition()

	if self.ts.settings.defaultFPP then
		self.perspective = "fpp"
		utils.switchCarCam("FPP")
	end

	Cron.After(0.4, function ()
		if self.ts.settings.noHudTrain then utils.toggleHUD(false) end
	end)
end

function train:unmount()
	StatusEffectHelper.RemoveStatusEffect(GetPlayer(), "GameplayRestriction.NoDriving")
	GetPlayer():QueueEvent(vehicleCameraResetEvent.new())

	self.perspective = "tpp"
	self.playerMounted = false
	GetPlayer():GetFPPCameraComponent():SetLocalPosition(Vector4.new(0, 0, 0, 0))
	utils.unmount()

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