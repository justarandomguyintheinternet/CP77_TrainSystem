local object = require("modules/classes/object")
local config = require("modules/utils/config")
local utils = require("modules/utils/utils")

station = {}

function station:new()
	local o = {}

    o.id = 0
	o.displayName = "defaultStation"
	o.center = Vector4.new(0, 0, 0, 0)
	o.trainExit = {pos = Vector4.new(0, 0, 0, 0), rot = Quaternion.new(0, 0, 0, 0)}
	o.portalPoint = {pos = Vector4.new(0, 0, 0, 0), rot = Quaternion.new(0, 0, 0, 0)}
	o.groundPoint = {pos = Vector4.new(0, 0, 0, 0), rot = Quaternion.new(0, 0, 0, 0)}
	o.objects = {}
	o.radius = 0
	o.useDoors = true
	o.loaded = false

	self.__index = self
   	return setmetatable(o, self)
end

function station:tpTo(point)
	Game.GetTeleportationFacility():Teleport(Game.GetPlayer(), point.pos,  GetSingleton('Quaternion'):ToEulerAngles(point.rot))
end

function station:exitToGround(ts)
	ts.observers.noSave = false
	ts.runtimeData.noTrains = false
	local rmStatus = Game['StatusEffectHelper::RemoveStatusEffect;GameObjectTweakDBID']
    rmStatus(Game.GetPlayer(), "GameplayRestriction.NoCombat")
	Game.ChangeZoneIndicatorPublic()
	self.loaded = false
	self:despawn()
	Game.GetTeleportationFacility():Teleport(Game.GetPlayer(), self.groundPoint.pos,  GetSingleton('Quaternion'):ToEulerAngles(self.groundPoint.rot))
end

function station:spawn()
	for _, obj in pairs(self.objects) do
		obj:spawn()
	end
	self.loaded = true
end

function station:despawn()
	print("despawn station id ", self.id)
	for _, obj in pairs(self.objects) do
		obj:despawn()
	end
	self.loaded = false
end

function station:update()
	for _, obj in pairs(self.objects) do
		obj:update()
	end
end

function station:inStation() -- Is player in station
	return utils.distanceVector(Game.GetPlayer():GetWorldPosition(), self.center) < self.radius
end

function station:nearExit()
	local near = false
	if utils.distanceVector(Game.GetPlayer():GetWorldPosition(), self.portalPoint.pos) < 1 then
		near = true
	end
	if utils.looksAtDoor(3.2) and self.useDoors then
		near = true
	end
	return near
end

function station:load(path)
	local data = config.loadFile(path)

    self.center = utils.getVector(data.center)
    self.displayName = data.displayName
    self.useDoors = data.useDoors
	self.id = data.id
	self.radius = data.radius
	self.trainExit = {pos = utils.getVector(data.trainExit.pos), rot = utils.getQuaternion(data.trainExit.rot)}
	self.portalPoint = {pos = utils.getVector(data.portalPoint.pos), rot = utils.getQuaternion(data.portalPoint.rot)}
	self.groundPoint = {pos = utils.getVector(data.groundPoint.pos), rot = utils.getQuaternion(data.groundPoint.rot)}
	for _, v in pairs(data.objects) do
		local obj = object:new(2001)
		obj:load(v)
		table.insert(self.objects, obj)
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
	data.objects = {}
	for _, v in pairs(self.objects) do
		local obj = v:getData()
		table.insert(data.objects, obj)
	end

    config.saveFile(path, data)
end

return station