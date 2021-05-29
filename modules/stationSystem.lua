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

	o.holdTime = 5
	o.activeTrain = nil
	o.trainInStation = false

	o.pathsData = {}
	o.currentPathsIndex = 0
	o.totalPaths = nil

	o.previousStationID = nil

	o.cronStopID = nil

	self.__index = self
   	return setmetatable(o, self)
end

function stationSys:load()
	for _, file in pairs(dir("data/stations")) do
        if file.name:match("^.+(%..+)$") == ".json" then
            local s = station:new()
            s:load("data/stations/" .. file.name)
            self.stations[s.id] = s
        end
    end
end

function stationSys:enter(id) -- Enter station from ground level
	self.onStation = true
	self.currentStation = self.stations[id]
	self.ts.observers.noSave = true
	Cron.After(0.3, function ()
		self.currentStation:tpTo(self.currentStation.portalPoint)
	end)
	Cron.After(0.32, function ()
		self.currentStation:spawn() -- Spawn AFTER start of tp, or it crashes when getting a loading screen, but only little bit after to make sure stuff spawns even if there is no loading screen
	end)

	--if #self.currentStation.objects ~= 0 then
		local cam = Game.GetPlayer():GetFPPCameraComponent()
		cam.pitchMin = 100

		Cron.After(0.5, function ()
			local cam = Game.GetPlayer():GetFPPCameraComponent()
			cam:ResetPitch()
		end)
	--end

	utils.togglePin(self, "exit", true, Vector4.new(self.currentStation.portalPoint.pos.x, self.currentStation.portalPoint.pos.y, self.currentStation.portalPoint.pos.z + 1, 0), "GetInVariant") --DistractVariant
	Game.ApplyEffectOnPlayer("GameplayRestriction.NoCombat")
	Game.ChangeZoneIndicatorSafe()

	self:activateArrival()
end

function stationSys:activateArrival()
	self.pathsData = self.ts.trackSys:mainGeneratePathData(self.currentStation)
	self.currentPathsIndex = 0
	self.totalPaths = #self.pathsData
	if self.activeTrain == nil then
		self.activeTrain = train:new(self)
		self.currentPathsIndex = self.currentPathsIndex + 1
		if self.currentPathsIndex > self.totalPaths then self.currentPathsIndex = 1 end
		self.activeTrain:loadRoute(self.pathsData[self.currentPathsIndex])
		self.activeTrain:spawn()
		self.activeTrain:startDrive("arrive")
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
	if self.activeTrain ~= nil then
		self.activeTrain:despawn()
		self.activeTrain = nil
	end
end

function stationSys:nearTrain()
	local near = false
	local target = Game.GetTargetingSystem():GetLookAtObject(Game.GetPlayer(), false, false)
	if target then
		if target:GetClassName().value == "vehicleAVBaseObject"then
			if utils.distanceVector(target:GetWorldPosition(), Game.GetPlayer():GetWorldPosition()) < 5 then
				near = true
			end
		end
	end
	return near
end

function stationSys:handleExitTrain()
	if self.ts.input.interactKey then
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
		if not self.currentStation:inStation() and not (self.activeTrain.playerMounted and not self.trainInStation) then
			--self.currentStation:tpTo(self.currentStation.portalPoint)
		end
		if self.currentStation:nearExit() then
			self.ts.hud.drawExit()
			if self.ts.input.interactKey then
                self.ts.input.interactKey = false
				for _, timer in pairs(Cron.timers) do
					if timer.id == self.cronStopID then
						Cron.Halt(timer.id)
					end
				end
				self:leave()
            end
		end
	end

	if self.onStation then
		self.ts.hud.drawDestinations(self)
	end

	if self.activeTrain ~= nil then
		self.activeTrain:update(deltaTime)
		if self.activeTrain.justArrived then
			self.activeTrain.justArrived = false
			self.trainInStation = true

			print("previous station id", self.previousStationID, " curren one is ", self.currentStation.id)

			if self.currentStation.id ~= self.previousStationID and self.previousStationID ~= nil then
				self.onStation = true
				print("previous station id was", self.previousStationID, "new curren one is ", self.currentStation.id)
				self.previousStationID = self.currentStation.id
				self.pathsData = self.ts.trackSys:mainGeneratePathData(self.currentStation)
				self.currentPathsIndex = 0
				self.totalPaths = #self.pathsData
				self.currentPathsIndex = self.currentPathsIndex + 1
				if self.currentPathsIndex > self.totalPaths then self.currentPathsIndex = 1 end
				self.activeTrain:loadRoute(self.pathsData[self.currentPathsIndex])
			end

			self.cronStopID = Cron.After(self.holdTime, function ()
				self.trainInStation = false
				self.activeTrain:startDrive("exit")
				if self.activeTrain.playerMounted then
					self.onStation = false
				end
			end)
		end

		if self.activeTrain.playerMounted and not self.trainInStation then
			Game.ApplyEffectOnPlayer("GameplayRestriction.VehicleBlockExit")
		else
			local rmStatus = Game['StatusEffectHelper::RemoveStatusEffect;GameObjectTweakDBID']
			rmStatus(Game.GetPlayer(), "GameplayRestriction.VehicleBlockExit")
		end

		self:handleExitTrain()
	end

	if self.trainInStation then
		if self:nearTrain() then
			self.ts.hud.drawExit()
			if self.ts.input.interactKey and not self.mountLocked then
				self.ts.input.interactKey = false
				self.activeTrain:mount()
				utils.togglePin(self, "exit", false, Vector4.new(self.currentStation.portalPoint.pos.x, self.currentStation.portalPoint.pos.y, self.currentStation.portalPoint.pos.z + 1, 0), "GetInVariant") --DistractVariant
			end
		end
	end

end

return stationSys