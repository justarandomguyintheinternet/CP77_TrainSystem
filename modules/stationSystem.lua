local station = require("modules/classes/station")
local Cron = require("modules/utils/Cron")
local utils = require("modules/utils/utils")
local train = require("modules/classes/train")
local soundObjects = require("modules/objectSystem").soundObjects

stationSys = {}

function stationSys:new(ts)
	local o = {}

	o.ts = ts
	o.stations = {}
	o.onStation = false
	o.currentStation = nil
	o.mountLocked = false

	o.holdTime = 10
	o.activeTrain = nil
	o.trainInStation = false

	o.pathsData = {}
	o.currentPathsIndex = 0
	o.totalPaths = nil

	o.previousStationID = nil

	o.cronStopID = nil

	o.inputHintsOriginal = nil
	o.jobTrackerOriginal = nil

	o.audioTimer = nil

	self.__index = self
   	return setmetatable(o, self)
end

function stationSys:load()
	for _, file in pairs(dir("data/stations")) do
        if file.name:match("^.+(%..+)$") == ".json" then
            local s = station:new(self.ts)
            s:load("data/stations/" .. file.name)
            self.stations[s.id] = s
        end
    end
end

function stationSys:enter() -- TP to station, toggle pin
	self.currentStation:tpTo(self.currentStation.portalPoint)
	self.onStation = true
	utils.togglePin(self, "exit", true, Vector4.new(self.currentStation.portalPoint.pos.x, self.currentStation.portalPoint.pos.y, self.currentStation.portalPoint.pos.z + 1, 0), "GetInVariant") --DistractVariant
	utils.setupTPPCam(self.ts.settings.camDist, self.ts.settings.autoCenter)
end

function stationSys:loadStation(id) -- Load station objects, start train spawning
	self.currentStation = self.stations[id]
	self.currentStation:spawn()
	self:activateArrival()
end

function stationSys:requestPaths()
	self.pathsData = self.ts.trackSys:mainGeneratePathData(self.currentStation)
	self.currentPathsIndex = 0
	self.totalPaths = #self.pathsData

	local last = {}
	local next = {}
	local ordered = {}
	for _, v in pairs(self.pathsData) do
		if v.dir == "next" then
			table.insert(next, v)
		else
			table.insert(last, v)
		end
	end

	if self.previousStationID == nil then
		local num = math.max(#next, #last)
		for i = 1, num do
			if #next >= i then table.insert(ordered, next[i]) end
			if #last >= i then table.insert(ordered, last[i]) end
		end
		self.pathsData = ordered
	else
		local prevPath = nil
		for _, v in pairs(self.pathsData) do
			--print(v.targetID, self.previousStationID)
			if v.targetID == self.previousStationID then
				prevPath = v
			end
		end
		if prevPath.dir == "next" then
			for _, p in pairs(last) do
				table.insert(ordered, p)
			end
			for _, p in pairs(next) do
				if p ~= prevPath then table.insert(ordered, p) end
			end
			table.insert(ordered, prevPath)
		else
			for _, p in pairs(next) do
				table.insert(ordered, p)
			end
			for _, p in pairs(last) do
				if p ~= prevPath then table.insert(ordered, p) end
			end
			table.insert(ordered, prevPath)
		end
		self.pathsData = ordered
	end
end

function stationSys:activateArrival()
	self:requestPaths()
	if self.activeTrain == nil then
		self.activeTrain = train:new(self)
		self.activeTrain.spawnStationID = self.currentStation.id
		self.currentPathsIndex = self.currentPathsIndex + 1
		if self.currentPathsIndex > self.totalPaths then self.currentPathsIndex = 1 end
		self.activeTrain:loadRoute(self.pathsData[self.currentPathsIndex])
		self.activeTrain:spawn()
		self.activeTrain:startDrive("arrive")
		self:startArriveTimer()
	end
end

function stationSys:requestNewTrain()
	self.currentPathsIndex = self.currentPathsIndex + 1
	if self.currentPathsIndex > self.totalPaths then self.currentPathsIndex = 1 end
	self.activeTrain:loadRoute(self.pathsData[self.currentPathsIndex])
	self.activeTrain:startDrive("arrive")
end

function stationSys:leave() -- Leave to ground level
	local t = 0
	if self.ts.settings.elevatorGlitch then
		t = 0.6
		utils.playGlitchEffect("fast_travel_glitch", GetPlayer())
	end

	Cron.After(t, function ()
		utils.togglePin(self, "exit", false)
		self.currentStation:exitToGround(self.ts)
		self.currentStation = nil
		self.onStation = false
		Cron.Halt(self.audioTimer)
		self.audioTimer = nil
		self.trainInStation = false
		self.previousStationID = nil
		if self.activeTrain ~= nil then
			self.activeTrain:despawn()
			self.activeTrain = nil
		end
		utils.removeTPPTweaks()
		Game.GetVehicleSystem():TogglePlayerActiveVehicle(GarageVehicleID.Resolve("Vehicle.v_standard2_archer_hella_player"), gamedataVehicleType.Car, true)
	end)
end

function stationSys:nearTrain()
	local train = self.activeTrain:getEntity()
	if not train then return end
	local maxDiff = 45
	local near = false

	local offset = utils.multVector(train:GetWorldForward(), 2)
	local diff1 = Vector4.GetAngleBetween(utils.subVector(self.activeTrain.pos, utils.addVector(Game.GetCameraSystem():GetActiveCameraForward(), GetPlayer():GetWorldPosition())), Game.GetCameraSystem():GetActiveCameraForward())
	local pos2 = utils.addVector(self.activeTrain.pos, offset)
	local diff2 = Vector4.GetAngleBetween(utils.subVector(pos2, utils.addVector(Game.GetCameraSystem():GetActiveCameraForward(), GetPlayer():GetWorldPosition())), Game.GetCameraSystem():GetActiveCameraForward())
	local pos3 = utils.subVector(self.activeTrain.pos, offset)
	local diff3 = Vector4.GetAngleBetween(utils.subVector(pos3, utils.addVector(Game.GetCameraSystem():GetActiveCameraForward(), GetPlayer():GetWorldPosition())), Game.GetCameraSystem():GetActiveCameraForward())

	if diff1 < maxDiff or diff2 < maxDiff or diff3 < maxDiff then
		if utils.distanceVector(self.activeTrain.pos, GetPlayer():GetWorldPosition()) < 6 then
			near = true
		end
	end
	return near
end

function stationSys:handleExitTrain()
	if self.ts.input.exit then
		if self.activeTrain.playerMounted and self.trainInStation then
			local t = 0
			if self.ts.settings.trainGlitch then
				t = 0.6
				utils.playGlitchEffect("fast_travel_glitch", GetPlayer())
			end

			Cron.After(t, function()
				self.activeTrain:unmount()
				utils.togglePin(self, "exit", true, Vector4.new(self.currentStation.portalPoint.pos.x, self.currentStation.portalPoint.pos.y, self.currentStation.portalPoint.pos.z + 1, 0), "GetInVariant") --DistractVariant
				self.mountLocked = true
				Cron.After(0.25, function ()
					self.mountLocked = false
				end)
				self.currentStation:tpTo(self.currentStation.trainExit)
			end)

		elseif self.activeTrain.playerMounted and not self.trainInStation then
			GetPlayer():SetWarningMessage(GetLocalizedText("LocKey#49538"))
		end
	end
end

function stationSys:handleAudio() -- Station announcement timer
	if self.audioTimer == nil then
		self.audioTimer = Cron.After(math.random(22, 70), function ()
			if not self.currentStation then return end

			for _, hash in pairs(soundObjects) do
				local ent = Game.FindEntityByID(entEntityID.new({hash = hash}))
				if ent then
					utils.playAudio(ent, "amb_g_city_el_adverts_watson_01_medium_metro_f_1_01", 6)
				end
			end
			Cron.After(7, function()
				for _, hash in pairs(soundObjects) do
					local ent = Game.FindEntityByID(entEntityID.new({hash = hash}))
					if ent then
						utils.stopAudio(ent, "amb_g_city_el_adverts_watson_01_medium_metro_f_1_01")
					end
				end
			end)

			self.audioTimer = nil
		end)
	end

	if self.onStation then
		Cron.Resume(self.audioTimer)
	else
		Cron.Pause(self.audioTimer)
	end
end

function stationSys:update(deltaTime)
	if self.currentStation then
		self.currentStation:update()
		if not self.currentStation:inStation() and not self.activeTrain.playerMounted and self.onStation then -- Wandered off
			self.currentStation:tpTo(self.currentStation.portalPoint)
		end
		if self.currentStation:nearExit() then
			self.ts.hud.exitVisible = true
			if self.ts.input.interactKey then
                self.ts.input.interactKey = false
				pcall(function ()
					for _, timer in pairs(Cron.timers) do
						if timer.id == self.cronStopID then
							Cron.Halt(timer.id)
						end
					end
				end)
				self:leave()
            end
		end

		self:handleAudio()
	end

	if self.onStation then
		self.ts.hud.destVisible = true
	end

	if self.activeTrain then
		self.activeTrain:update(deltaTime)
		if self.activeTrain.justArrived then
			self.activeTrain.justArrived = false
			self.trainInStation = true

			if self.activeTrain.playerMounted then
				Game.GetTransactionSystem():RemoveItem(GetPlayer(), gameItemID.FromTDBID(TweakDBID.new("Items.money")), self.ts.settings.moneyPerStation)
			end

			if self.currentStation.id ~= self.previousStationID and self.previousStationID ~= nil then
				self.onStation = true
				self:requestPaths()
				self.previousStationID = self.currentStation.id
				self.currentPathsIndex = self.currentPathsIndex + 1
				if self.currentPathsIndex > self.totalPaths then self.currentPathsIndex = 1 end
				self.activeTrain:loadRoute(self.pathsData[self.currentPathsIndex])
			end

			self.cronStopID = Cron.After(self.currentStation.holdTime * self.ts.settings.holdMult, function ()
				if not self.activeTrain then return end
				self.trainInStation = false
				if self.activeTrain.playerMounted then
					self.onStation = false
				end
				--self.activeTrain:startDrive("exit") --is done inside startExitTimer, calling it twice is bad
				--self.activeTrain:loadRoute(self.pathsData[self.currentPathsIndex])
				self:startExitTimer()
			end)

			self:startHoldTimer()
		end

		if self.activeTrain.playerMounted and not self.trainInStation then
			utils.applyStatus("GameplayRestriction.VehicleBlockExit")
		else
			utils.removeStatus("GameplayRestriction.VehicleBlockExit")
		end

		self:handleExitTrain()
	end

	if self.trainInStation and self.activeTrain ~= nil then
		if self:nearTrain() and (not self.activeTrain.playerMounted) then
			self.ts.hud.trainVisible = true
			if self.ts.input.interactKey and not self.mountLocked and not self.activeTrain.justArrived then
				local t = 0
				if self.ts.settings.trainGlitch then
					t = 0.6
					utils.playGlitchEffect("fast_travel_glitch", GetPlayer())
				end

				Cron.After(t, function()
					self.ts.input.interactKey = false
					self.activeTrain:mount()
					utils.togglePin(self, "exit", false, Vector4.new(self.currentStation.portalPoint.pos.x, self.currentStation.portalPoint.pos.y, self.currentStation.portalPoint.pos.z + 1, 0), "GetInVariant") --DistractVariant
				end)
			end
		end
	end

	if self.ts.observers.noSave then -- Mod is active
		Game.GetScriptableSystemsContainer():Get("PreventionSystem"):OnSetWantedLevel(SetWantedLevel.new({wantedLevel =EPreventionHeatStage.Heat_0 }))
		utils.changeZoneIndicatorSafe()

		local gtaTravel = GetMod("gtaTravel") -- Disable gtaTravel
		if gtaTravel then
			if gtaTravel.flyPath then
				gtaTravel.flyPath = false
				gtaTravel.resetPitch = true
			end
		end
	end
end

function stationSys:startHoldTimer()
	self.ts.observers.timetableValue = self.currentStation.holdTime * self.ts.settings.holdMult
	Cron.Every(1, {tick = 0}, function(timer)
		self.ts.observers.timetableValue = self.ts.observers.timetableValue - 1
		if self.activeTrain == nil then
			timer:Halt()
			return
		end
		if self.ts.observers.timetableValue <= 0 then
			timer:Halt()
		end
		if self.activeTrain.driving then
			timer:Halt()
		end
	end)
end

function stationSys:startExitTimer()
	self.activeTrain:startDrive("aaa") -- Sets pointIndex and pos properly for remainingLength calcs
	local exitTime = math.floor((self.activeTrain:getRemainingExitLength() / self.activeTrain.originalSpeed) + 1.5 + 35 / self.activeTrain.originalSpeed)

	if self.currentPathsIndex + 1 > self.totalPaths then
		self.activeTrain:loadRoute(self.pathsData[1])
	else
		self.activeTrain:loadRoute(self.pathsData[self.currentPathsIndex + 1])
	end
	self.activeTrain:startDrive("arrive")

	local arriveTime = math.floor((self.activeTrain:getRemainingLength() / self.activeTrain.originalSpeed) + 1.5 + 35 / self.activeTrain.originalSpeed)

	self.activeTrain:loadRoute(self.pathsData[self.currentPathsIndex])
	self.activeTrain:startDrive("exit")

	self.ts.observers.timetableValue = exitTime + arriveTime + 2 -- 2 for the time where the train dissapears

	Cron.Every(1, {tick = 0}, function(timer)
		self.ts.observers.timetableValue = self.ts.observers.timetableValue - 1
		if self.ts.observers.timetableValue <= 0 then
			timer:Halt()
		end
		if self.activeTrain == nil then
			timer:Halt()
			return
		end
	end)
end

function stationSys:startArriveTimer()
	self.ts.observers.timetableValue = math.floor((self.activeTrain:getRemainingLength() / self.activeTrain.originalSpeed) + 1.5 + 35 / self.activeTrain.originalSpeed)
	Cron.Every(1, {tick = 0}, function(timer)
		self.ts.observers.timetableValue = self.ts.observers.timetableValue - 1
		if self.ts.observers.timetableValue <= 0 then
			timer:Halt()
		end
		if self.activeTrain == nil then
			timer:Halt()
			return
		end
		if not self.activeTrain.driving then
			timer:Halt()
		end
	end)
end

return stationSys