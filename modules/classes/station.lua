local config = require("modules/utils/config")
local utils = require("modules/utils/utils")
local Cron = require("modules/utils/Cron")
local settings = require("modules/utils/GameSettings")
local spawnEntities = false -- For potential game updates that break sectors

station = {}

function station:new(ts)
	local o = {}

    o.id = 0
	o.displayName = "defaultStation"
	o.center = Vector4.new(0, 0, 0, 0)
	o.trainExit = {pos = Vector4.new(0, 0, 0, 0), rot = Quaternion.new(0, 0, 0, 0)}
	o.portalPoint = {pos = Vector4.new(0, 0, 0, 0), rot = Quaternion.new(0, 0, 0, 0)}
	o.groundPoint = {pos = Vector4.new(0, 0, 0, 0), rot = Quaternion.new(0, 0, 0, 0)}

	o.objectFileName = ""
	o.objects = {}
	o.objectIDS = {}

	o.exitDoorPosition = Vector4.new(0, 0, 0, 0)
	o.exitDoorSealed = true

	o.spawnOffset = -10

	o.radius = 0
	o.minZ = 0
	o.holdTime = 10
	o.useDoors = true
	o.loaded = false
	o.ts = ts

	self.__index = self
   	return setmetatable(o, self)
end

function station:tpTo(point)
	Game.GetTeleportationFacility():Teleport(GetPlayer(), point.pos,  point.rot:ToEulerAngles()) -- Fuck this shit and its stoopid rotation / fuck unmount
end

function station:exitToGround(ts)
	local entry = ts.entrySys:findEntryByID(self.id)

	local playerElevatorPos = utils.subVector(entry.elevatorPosition, Vector4.new(0, 1.1, 0, 0))-- Adjusted to make the player stand less in front of the wall
    local playerSecondaryElevatorPos = utils.subVector(entry.secondaryPosition, Vector4.new(0, 1.1, 0, 0))

	if entry.useSecondaryElevator then
        local secondID = utils.spawnObject(entry.elevatorPath, entry.secondaryPosition, EulerAngles.new(0, 0, 0):ToQuat())
        Game.GetTeleportationFacility():Teleport(GetPlayer(), playerElevatorPos, entry.elevatorPlayerRotation)
        Cron.After(0.25, function ()
            Game.GetTeleportationFacility():Teleport(GetPlayer(), playerSecondaryElevatorPos, entry.elevatorPlayerRotation)
        end)
        Cron.After(self.ts.settings.elevatorTime, function ()
			if not spawnEntities then return end
			exEntitySpawner.Despawn(Game.FindEntityByID(secondID))
            secondID = nil
        end)
    else
        Game.GetTeleportationFacility():Teleport(GetPlayer(), playerElevatorPos, entry.elevatorPlayerRotation)
    end

	self.loaded = false
	self:despawn()

	utils.playAudio(GetPlayer(), "dev_elevator_02_movement_start", 3)

    Cron.After(self.ts.settings.elevatorTime, function ()
        ts.observers.noSave = false
		ts.observers.noTrains = false
		utils.removeStatus("GameplayRestriction.NoCombat")

		utils.changeZoneIndicatorPublic()
		Game.GetTeleportationFacility():Teleport(GetPlayer(), self.groundPoint.pos,  self.groundPoint.rot:ToEulerAngles())

		utils.stopAudio(GetPlayer(), "dev_elevator_02_movement_start")
        utils.playAudio(GetPlayer(), "dev_elevator_02_movement_stop", 3)

		settings.Set("/interface/hud/input_hints", ts.stationSys.inputHintsOriginal)
		settings.Set("/interface/hud/quest_tracker", ts.stationSys.jobTrackerOriginal)
    end)

	Cron.After(self.ts.settings.elevatorTime - 0.6, function()
		if not self.ts.settings.elevatorGlitch then return end
        utils.playGlitchEffect("fast_travel_glitch", GetPlayer())
    end)
end

function station:spawn()
	if not spawnEntities then return end

	for _, o in pairs(self.objects) do
		local id = utils.spawnObject(o.path, utils.getVector(o.pos), utils.getEuler(o.rot):ToQuat(), o.app)
        table.insert(self.objectIDS, id)
	end
	self.loaded = true
end

function station:despawn()
	if not spawnEntities then return end

	for _, id in pairs(self.objectIDS) do
		if Game.FindEntityByID(id) ~= nil then
			exEntitySpawner.Despawn(Game.FindEntityByID(id))
		end
	end
	self.objectIDS = {}
	self.loaded = false
end

function station:update()
end

function station:inStation() -- Is player in station
	local radius = utils.distanceVector(GetPlayer():GetWorldPosition(), self.center) < (self.radius * 1.5)
	local z = GetPlayer():GetWorldPosition().z > self.minZ
	return radius and z
end

function station:nearExit()
	local target = Game.GetTargetingSystem():GetLookAtObject(GetPlayer(), false, true)
	local near = false

	if target and not (utils.distanceVector(target:GetWorldPosition(), Vector4.new(-1430.782, 458.094, 51.818, 0)) < 0.1) then -- Ugly hardcoded workaround for the force open door at rep way north :(
		if target:GetClassName().value == "Door" then
			---@type DoorControllerPS
			local targetPS = target:GetDevicePS()
			if not targetPS:IsLocked() then targetPS:ToggleLockOnDoor() end
			if targetPS:IsOpen() then targetPS:ToggleOpenOnDoor() end
		end

		if utils.isVector(target:GetWorldPosition(), self.exitDoorPosition) then
			if self.exitDoorSealed then
				pcall(function ()
					local targetPS = target:GetDevicePS()
					if not targetPS:IsLocked() then targetPS:ToggleLockOnDoor() end
				end)
			end
			if Vector4.Distance(GetPlayer():GetWorldPosition(), target:GetWorldPosition()) < 2.7 then
				near = true
			end
		elseif Vector4.Distance(GetPlayer():GetWorldPosition(), target:GetWorldPosition()) < 2.7 then
			self:handleFakeDoor(target)
		end
	end

	return near
end

function station:handleFakeDoor(target)
	if (target:GetClassName().value == "FakeDoor" or target:GetClassName().value == "Door") and self.useDoors then
		self.ts.hud.doorVisible = true
		if self.ts.input.interactKey then
			self.ts.input.interactKey = false

			local pos1 = utils.addVector(target:GetWorldPosition(), target:GetWorldForward())
			local pos2 = utils.subVector(target:GetWorldPosition(), target:GetWorldForward())

			if Vector4.Distance(GetPlayer():GetWorldPosition(), pos1) > Vector4.Distance(GetPlayer():GetWorldPosition(), pos2) then
				Game.GetTeleportationFacility():Teleport(GetPlayer(), pos1, GetPlayer():GetWorldOrientation():ToEulerAngles())
			else
				Game.GetTeleportationFacility():Teleport(GetPlayer(), pos2,  GetPlayer():GetWorldOrientation():ToEulerAngles())
			end
		end
	end
end

function station:load(path)
	local data = config.loadFile(path)

    self.center = utils.getVector(data.center)
    self.displayName = data.displayName
    self.useDoors = data.useDoors
	self.id = data.id
	self.radius = data.radius
	self.minZ = data.minZ
	self.spawnOffset = data.spawnOffset
	self.trainExit = {pos = utils.getVector(data.trainExit.pos), rot = utils.getQuaternion(data.trainExit.rot)}
	self.portalPoint = {pos = utils.getVector(data.portalPoint.pos), rot = utils.getQuaternion(data.portalPoint.rot)}
	self.groundPoint = {pos = utils.getVector(data.groundPoint.pos), rot = utils.getQuaternion(data.groundPoint.rot)}
	self.holdTime = data.holdTime

	self.objectFileName = data.objectFileName
	self.exitDoorPosition = utils.getVector(data.exitDoorPosition)
	self.exitDoorSealed = data.exitDoorSealed
	if self.objectFileName ~= "" then
		self.objects = config.loadFile("data/objects/stations/" .. self.objectFileName)
	end
end

function station:save(path)
	local data = {}
	data.center = utils.fromVector(self.center)
	data.trainExit = {pos = utils.fromVector(self.trainExit.pos), rot = utils.fromQuaternion(self.trainExit.rot)}
	data.portalPoint = {pos = utils.fromVector(self.portalPoint.pos), rot = utils.fromQuaternion(self.portalPoint.rot)}
	data.groundPoint = {pos = utils.fromVector(self.groundPoint.pos), rot = utils.fromQuaternion(self.groundPoint.rot)}
	data.displayName = self.displayName
	data.id = self.id
	data.useDoors = self.useDoors
	data.radius = self.radius
	data.spawnOffset = self.spawnOffset
	data.minZ = self.minZ
	data.holdTime = self.holdTime

	data.objectFileName = self.objectFileName
	data.exitDoorPosition = utils.fromVector(self.exitDoorPosition)
	data.exitDoorSealed = self.exitDoorSealed

    config.saveFile(path, data)
end

return station