local object = require("modules/classes/object")
local utils = require("modules/utils/utils")
local Cron = require("modules/utils/Cron")

train = {}

function train:new()
	local o = {}

	o.arrivalPath = {}
	o.exitPath = {}
	o.activePath = {}
	o.driving = false
	o.speed = 20
	o.pointIndex = 1

	o.carName = "Vehicle.cs_savable_makigai_maimai"
	o.carOffset = Vector4.new(0, 0, 1, 0)
	o.carLayer = 2010
	o.trainLayer = 2011
	o.carObject = nil
	o.trainObject = nil

	o.playerMounted = false
	o.justArrived = false

	o.pos = Vector4.new(0, 0, 0, 0)
	o.rot = Quaternion.new(0.1, 0, 0, 0)

	o.trainObj2 = nil

	self.__index = self
   	return setmetatable(o, self)
end

function train:spawn()
	local point = self.arrivalPath[#self.arrivalPath]
	self.carObject = object:new(self.carLayer)
	self.carObject.name = self.carName

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
	else
		self.activePath = self.exitPath
		self.driving = true
	end
end

function train:update(deltaTime)
	if self.driving then
		print("driving, pos", self.pos, "point index: ", self.pointIndex, "points: ", #self.activePath)
		if utils.distanceVector(self.pos, self.activePath[self.pointIndex + 1].pos) > self.speed * deltaTime then
			print("below next point")
			local todo = self.speed * deltaTime -- How much i want to do
			local dist = utils.distanceVector(self.pos, self.activePath[self.pointIndex + 1].pos) -- How much the total would been
			local factor = todo / dist -- How much percent of the dist should be done
			local dirVector = utils.subVector(self.activePath[self.pointIndex + 1].pos, self.pos)
			self.pos = utils.addVector(utils.multVector(dirVector, factor), self.pos)

			local newEuler = utils.subEuler(GetSingleton('Quaternion'):ToEulerAngles(self.activePath[self.pointIndex + 1].rot), GetSingleton('Quaternion'):ToEulerAngles(self.rot))
			self.rot = GetSingleton('EulerAngles'):ToQuat(utils.addEuler(utils.multEuler(newEuler, factor), GetSingleton('Quaternion'):ToEulerAngles(self.rot)))
		else
			local todo = self.speed * deltaTime
			while todo > 0 do
				print("todo bigger 0" , todo)
				if utils.distanceVector(self.pos, self.activePath[self.pointIndex + 1].pos) < todo then
					print("would get over to next one, current point index", self.pointIndex)
					todo = todo - utils.distanceVector(self.pos, self.activePath[self.pointIndex + 1].pos)
					self.pos = self.activePath[self.pointIndex + 1].pos
					self.rot = self.activePath[self.pointIndex + 1].rot
					self:handlePoint(self.activePath[self.pointIndex + 1])
					self.pointIndex = self.pointIndex + 1
					if self.pointIndex == #self.activePath then
						self.justArrived = true
						self.driving = false
					end
					print("got over, new todo ", todo, "new p index ", self.pointIndex)
				else
					local dist = utils.distanceVector(self.pos, self.activePath[self.pointIndex + 1].pos) -- How much the total would been
					local factor = todo / dist -- How much percent of the dist should be done
					local dirVector = utils.subVector(self.activePath[self.pointIndex + 1].pos, self.pos)
					self.pos = utils.addVector(utils.multVector(dirVector, factor), self.pos)

					local newEuler = utils.subEuler(GetSingleton('Quaternion'):ToEulerAngles(self.activePath[self.pointIndex + 1].rot), GetSingleton('Quaternion'):ToEulerAngles(self.rot))
					self.rot = GetSingleton('EulerAngles'):ToQuat(utils.addEuler(utils.multEuler(newEuler, factor), GetSingleton('Quaternion'):ToEulerAngles(self.rot)))
					todo = 0
				end
			end
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
end

function train:updateLocation(obj)
	if obj == "car" then
		self.carObject.pos = utils.addVector(self.pos, self.carOffset)
		self.carObject.rot = self.rot
	else
		self.trainObject.pos = self.pos
		self.trainObject.rot = self.rot
	end
end

function train:handlePoint(point)
	-- detect load / unload triggers
end

function train:mount()

end

function train:unmount()

end

return train