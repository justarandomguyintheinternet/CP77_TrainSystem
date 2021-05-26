trackSys = {}

function trackSys:new()
	local o = {}

	o.tracks = {}

	self.__index = self
   	return setmetatable(o, self)
end

function trackSys:getDestinations(station)

end

function trackSys:calcRoute(origin, destination)

end

return trackSys