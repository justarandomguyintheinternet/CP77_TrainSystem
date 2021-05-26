train = {}

function train:new()
	local o = {}

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