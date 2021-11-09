local station = require("modules/classes/station")
local Cron = require("modules/utils/Cron")
local utils = require("modules/utils/utils")
local train = require("modules/classes/train")

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
	o.backUpTrain = nil

	o.cronStopID = nil

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
	utils.setupTPPCam(self.ts.settings.camDist)
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
			print(v.targetID, self.previousStationID)
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
	utils.togglePin(self, "exit", false)
	self.currentStation:exitToGround(self.ts)
	self.currentStation = nil
	self.onStation = false
	self.previousStationID = nil
	if self.activeTrain ~= nil then
		self.activeTrain:despawn()
		self.activeTrain = nil
	end
	if self.backUpTrain ~= nil then
		self.backUpTrain:despawn()
		self.backUpTrain = nil
	end
	utils.removeTPPTweaks()
end

function stationSys:nearTrain()
	local near = false
	local target = Game.GetTargetingSystem():GetLookAtObject(Game.GetPlayer(), false, false)
	if target then
		if target:GetClassName().value == "vehicleAVBaseObject" or target:GetClassName().value == "vehicleBikeBaseObject" then
			if utils.distanceVector(self.activeTrain.pos, Game.GetPlayer():GetWorldPosition()) < 7.5 then
				near = true
			end
		end
	end
	return near
end

function stationSys:handleExitTrain()
	if self.ts.input.exit then
		if self.activeTrain.playerMounted and self.trainInStation then
			self.mountLocked = true
			self.activeTrain:unmount()
			utils.togglePin(self, "exit", true, Vector4.new(self.currentStation.portalPoint.pos.x, self.currentStation.portalPoint.pos.y, self.currentStation.portalPoint.pos.z + 1, 0), "GetInVariant") --DistractVariant
			Cron.After(0.25, function ()
				self.mountLocked = false
			end)
			self.currentStation:tpTo(self.currentStation.trainExit)
		elseif self.activeTrain.playerMounted and not self.trainInStation then
			Game.GetPlayer():SetWarningMessage("Cant do that now")
		end
	end
end

function stationSys:update(deltaTime)
	if self.currentStation then
		self.currentStation:update()
		if not self.currentStation:inStation() and not self.activeTrain.playerMounted and self.onStation then
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
	end

	if self.onStation then
		self.ts.hud.destVisible = true
	end

	if self.activeTrain ~= nil then
		self.activeTrain:update(deltaTime)
		if self.activeTrain.justArrived then
			self.activeTrain.justArrived = false
			self.trainInStation = true

			if self.activeTrain.playerMounted then
				local tdbid = TweakDBID.new("Items.money")
				local moneyId = GetSingleton('gameItemID'):FromTDBID(tdbid)
				Game.GetTransactionSystem():RemoveItem(Game.GetPlayer(), moneyId, self.ts.settings.moneyPerStation)
			end

			print("previous station id", self.previousStationID, " curren one is ", self.currentStation.id)

			if self.currentStation.id ~= self.previousStationID and self.previousStationID ~= nil then
				self.onStation = true
				print("previous station id was", self.previousStationID, "new curren one is ", self.currentStation.id)
				self:requestPaths()
				self.previousStationID = self.currentStation.id
				self.currentPathsIndex = self.currentPathsIndex + 1
				if self.currentPathsIndex > self.totalPaths then self.currentPathsIndex = 1 end
				self.activeTrain:loadRoute(self.pathsData[self.currentPathsIndex])
			end

			self.cronStopID = Cron.After(self.currentStation.holdTime * self.ts.settings.holdMult, function ()
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
			Game.ApplyEffectOnPlayer("GameplayRestriction.VehicleBlockExit")
		else
			local rmStatus = Game['StatusEffectHelper::RemoveStatusEffect;GameObjectTweakDBID']
			rmStatus(Game.GetPlayer(), "GameplayRestriction.VehicleBlockExit")
		end

		self:handleExitTrain()
	end

	if self.trainInStation and self.activeTrain ~= nil then
		if self:nearTrain() and not self.activeTrain.playerMounted then
			self.ts.hud.trainVisible = true
			if self.ts.input.interactKey and not self.mountLocked and not self.activeTrain.justArrived then
				self.ts.input.interactKey = false
				self.activeTrain:mount()
				utils.togglePin(self, "exit", false, Vector4.new(self.currentStation.portalPoint.pos.x, self.currentStation.portalPoint.pos.y, self.currentStation.portalPoint.pos.z + 1, 0), "GetInVariant") --DistractVariant
			end
		end
	end
end

function stationSys:startHoldTimer()
	self.ts.observers.timetableValue = self.currentStation.holdTime * self.ts.settings.holdMult
	Cron.Every(1, {tick = 0}, function(timer)
		self.ts.observers.timetableValue = self.ts.observers.timetableValue - 1
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

	self.ts.observers.timetableValue = exitTime + arriveTime

	Cron.Every(1, {tick = 0}, function(timer)
		self.ts.observers.timetableValue = self.ts.observers.timetableValue - 1
		if self.ts.observers.timetableValue <= 0 then
			timer:Halt()
		end
		if not self.activeTrain.driving then
			timer:Halt()
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
		if not self.activeTrain.driving then
			timer:Halt()
		end
	end)
end

return stationSys