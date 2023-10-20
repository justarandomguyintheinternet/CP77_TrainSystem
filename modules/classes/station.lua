local config = require("modules/utils/config")
local utils = require("modules/utils/utils")

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
	o.bigRange = 0
	o.minZ = 0
	o.holdTime = 10
	o.useDoors = true
	o.ts = ts

	self.__index = self
   	return setmetatable(o, self)
end

function station:load(path)
	local data = config.loadFile(path)

    self.center = utils.getVector(data.center)
    self.displayName = data.displayName
    self.useDoors = data.useDoors
	self.id = data.id
	self.radius = data.radius
	self.bigRange = data.bigRange
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
	data.bigRange = self.bigRange
	data.spawnOffset = self.spawnOffset
	data.minZ = self.minZ
	data.holdTime = self.holdTime

	data.objectFileName = self.objectFileName
	data.exitDoorPosition = utils.fromVector(self.exitDoorPosition)
	data.exitDoorSealed = self.exitDoorSealed

    config.saveFile(path, data)
end

return station