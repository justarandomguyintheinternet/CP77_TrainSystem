train = {}

function train:new()
	local o = {}

	o.route = {}

	o.carName = "Vehicle.cs_savable_makigai_maimai"
	o.carID = nil
	o.trainID = nil
	o.spawned = false

	self.__index = self
   	return setmetatable(o, self)
end

function train:spawn(point)

end

function train:loadRoute(route)

end

function train:startDrive()

end

function train:update(deltaTime)

end

function train:mount()

end

function train:unmount()

end

return train