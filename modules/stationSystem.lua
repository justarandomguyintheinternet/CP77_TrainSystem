local station = require("modules/classes/station")
local Cron = require("modules/utils/Cron")
local utils = require("modules/utils/utils")
local hud = require("modules/ui/hud")

stationSys = {}

-- API:
	-- metro has API for
		-- Current line
		-- Audio Events
		-- Or just target / line change event
		-- Current target
		-- Has player

-- Player in metro loop:
	-- Apply restricitions, disable trains

function stationSys:new(ts)
	local o = {}

	o.ts = ts
	o.stations = {}
	o.metro = nil

	o.inSmallRange = false
	o.inBigRange = false
	o.bigRangeStation = nil
	o.fakeDoor = nil

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

	self:registerKeybinds()
end

function stationSys:registerKeybinds()
    input.registerKeybind("use_door", "UI_Apply", function()
		if not self.fakeDoor then return end

		self:useFakeDoor(self.fakeDoor)
    end)
end

---Get the closest object (.center) to the player
---@param data table
---@return table|nil
function stationSys:getClosest(data)
    local closest = nil
    local closestDist = 999999999999

    for _, location in pairs(data) do
        local distance = GetPlayer():GetWorldPosition():Distance(location.center)
        if distance < closestDist then
            closestDist = distance
            closest = location
        end
    end

    return closest
end

---Get a table of the stations within the specified range
---@param range "small"|"big"
---@return table
function stationSys:getInRange(range)
	local inRange = {}
	for _, station in pairs(self.stations) do
		local dist = station.radius
		if range == "big" then dist = station.bigRange end
		if GetPlayer():GetWorldPosition():Distance(station.center) <= dist then
			table.insert(inRange, station)
		end
	end

	return inRange
end

---Handle the interactions and logic for fake doors, if on a station
function stationSys:handleFakeDoors()
	self.fakeDoor = self:getFakeDoor()

	if not self.fakeDoor then
		hud.toggleInteraction(false, "use_door")
	else
		utils.lockDoor(self.fakeDoor)
		hud.toggleInteraction(true, "use_door")
	end
end

---Returns the door object of a targeted fake door, if its a valid door
---@return gameObject|nil
function stationSys:getFakeDoor()
	if not self.inSmallRange then return end

	local target = Game.GetTargetingSystem():GetLookAtObject(GetPlayer(), false, true)

	if not target then return end
	if target:GetClassName().value ~= "FakeDoor" and target:GetClassName().value ~= "Door" then return end
	if Vector4.Distance(GetPlayer():GetWorldPosition(), target:GetWorldPosition()) > 2.7 then return end
	if target:GetWorldPosition():Distance(Vector4.new(-1430.782, 458.094, 51.818, 0)) < 0.1 then return end -- Ugly hardcoded workaround for the force open door at rep way north :(

	local station = self:getClosest(self.stations)

	if not station.useDoors then return end
	if utils.isVector(target:GetWorldPosition(), station.exitDoorPosition) then return end

	return target
end

---Uses the given object as a door
---@param door gameObject
function stationSys:useFakeDoor(door)
	local pos1 = utils.addVector(door:GetWorldPosition(), door:GetWorldForward())
	local pos2 = utils.subVector(door:GetWorldPosition(), door:GetWorldForward())

	if GetPlayer():GetWorldPosition():Distance(pos1) > GetPlayer():GetWorldPosition():Distance(pos2) then
		utils.tp(GetPlayer(), pos1, door:GetWorldOrientation())
	else
		utils.tp(GetPlayer(), pos2, EulerAngles.new(0, 0, door:GetWorldOrientation():ToEulerAngles().yaw + 180))
	end
end

function stationSys:sessionEnd()
	self.inSmallRange = false
	self.inBigRange = false
	self.bigRangeStation = nil

	if self.metro then
		self.metro:despawn()
		self.metro = nil
	end
end

-- Handle logic related to the "big" range of a station, responsible for activating metro arrivals
function stationSys:handleBigRange()
	local inRange = self:getInRange("big")
	local closest = self:getClosest(inRange)

	if not closest and self.inBigRange then
		self.inBigRange = false
		self.bigRangeStation = nil
		observers.noTrains = false
		if self.metro and not self.metro:playerBoarded() then
			self.metro:despawn()
			self.metro = nil
			print("stop arrival")
		end
	end

	-- Station has changed from none to one, or from one to another
	if closest and (not self.inBigRange or closest.id ~= self.bigRangeStation.id) then
		if self.metro then
			if not self.metro:playerBoarded() and self.metro.activeLine.targetStationID ~= closest.id then
				-- respawn metro to closest station
				-- maybe let it exit first, then change spawn location
				print("relocate metro")
			end
		else
			print("start arrival", closest.id)
			self.metro = require("modules/classes/train"):new(self)
			self.metro:startArrival(closest.id, -1)
			self.metro:spawn(self.metro.path[1])
		end

		self.bigRangeStation = closest
		self.inBigRange = true
		observers.noTrains = true
	end
end

-- Handle logic related to "small" range (Player is on station), such as updating timetables, playing audio, applying restrictions
function stationSys:handleSmallRange()
	local inRange = self:getInRange("small")
	local closest = self:getClosest(inRange)

	if not closest and self.inSmallRange then
		self.inSmallRange = false
		utils.applyGeneralRestrictions(false)
	end

	if closest and not self.inSmallRange then
		self.inSmallRange = true
		utils.applyGeneralRestrictions(true)
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
	if self.metro then
		self.metro:update(deltaTime)
	end

	self:handleSmallRange()
	self:handleBigRange()
	self:handleFakeDoors()
	-- if self.currentStation then
	-- 	self.currentStation:update()
	-- 	if not self.currentStation:inStation() and not self.activeTrain.playerMounted and self.onStation then -- Wandered off
	-- 	end
	-- 	if self.currentStation:nearExit() then
	-- 		self.ts.hud.exitVisible = true
	-- 		if self.ts.input.interactKey then
    --             self.ts.input.interactKey = false
	-- 			pcall(function ()
	-- 				for _, timer in pairs(Cron.timers) do
	-- 					if timer.id == self.cronStopID then
	-- 						Cron.Halt(timer.id)
	-- 					end
	-- 				end
	-- 			end)
	-- 			self:leave()
    --         end
	-- 	end

	-- 	self:handleAudio()
	-- end

	-- if self.onStation then
	-- 	self.ts.hud.destVisible = true
	-- end

	-- if self.activeTrain then
	-- 	self.activeTrain:update(deltaTime)
	-- 	if self.activeTrain.justArrived then
	-- 		self.activeTrain.justArrived = false
	-- 		self.trainInStation = true

	-- 		if self.activeTrain.playerMounted then
	-- 			Game.GetTransactionSystem():RemoveItem(GetPlayer(), gameItemID.FromTDBID(TweakDBID.new("Items.money")), self.ts.settings.moneyPerStation)
	-- 		end

	-- 		if self.currentStation.id ~= self.previousStationID and self.previousStationID ~= nil then
	-- 			self.onStation = true
	-- 			self:requestPaths()
	-- 			self.previousStationID = self.currentStation.id
	-- 			self.currentPathsIndex = self.currentPathsIndex + 1
	-- 			if self.currentPathsIndex > self.totalPaths then self.currentPathsIndex = 1 end
	-- 			self.activeTrain:loadRoute(self.pathsData[self.currentPathsIndex])
	-- 		end

	-- 		self.cronStopID = Cron.After(self.currentStation.holdTime * self.ts.settings.holdMult, function ()
	-- 			if not self.activeTrain then return end
	-- 			self.trainInStation = false
	-- 			if self.activeTrain.playerMounted then
	-- 				self.onStation = false
	-- 			end
	-- 			--self.activeTrain:startDrive("exit") --is done inside startExitTimer, calling it twice is bad
	-- 			--self.activeTrain:loadRoute(self.pathsData[self.currentPathsIndex])
	-- 			self:startExitTimer()
	-- 		end)

	-- 		self:startHoldTimer()
	-- 	end

	-- 	if self.activeTrain.playerMounted and not self.trainInStation then
	-- 		Game.ApplyEffectOnPlayer("GameplayRestriction.VehicleBlockExit")
	-- 	else
	-- 		StatusEffectHelper.RemoveStatusEffect(GetPlayer(), "GameplayRestriction.VehicleBlockExit")
	-- 	end

	-- 	self:handleExitTrain()
	-- end

	-- if self.trainInStation and self.activeTrain ~= nil then
	-- 	if self:nearTrain() and (not self.activeTrain.playerMounted) then
	-- 		self.ts.hud.trainVisible = true
	-- 		if self.ts.input.interactKey and not self.mountLocked and not self.activeTrain.justArrived then
	-- 			local t = 0
	-- 			if self.ts.settings.trainGlitch then
	-- 				t = 0.6
	-- 				utils.playGlitchEffect("fast_travel_glitch", GetPlayer())
	-- 			end

	-- 			Cron.After(t, function()
	-- 				self.ts.input.interactKey = false
	-- 				self.activeTrain:mount()
	-- 				utils.togglePin(self, "exit", false, Vector4.new(self.currentStation.portalPoint.pos.x, self.currentStation.portalPoint.pos.y, self.currentStation.portalPoint.pos.z + 1, 0), "GetInVariant") --DistractVariant
	-- 			end)
	-- 		end
	-- 	end
	-- end

	-- if self.ts.observers.noSave then -- Mod is active
	-- 	Game.GetScriptableSystemsContainer():Get("PreventionSystem"):SetHeatStage(EPreventionHeatStage.Heat_0)
	-- 	Game.ChangeZoneIndicatorSafe()

	-- 	local gtaTravel = GetMod("gtaTravel") -- Disable gtaTravel
	-- 	if gtaTravel then
	-- 		if gtaTravel.flyPath then
	-- 			gtaTravel.flyPath = false
	-- 			gtaTravel.resetPitch = true
	-- 		end
	-- 	end
	-- end
end

return stationSys