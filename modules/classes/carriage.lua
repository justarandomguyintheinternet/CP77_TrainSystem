local utils = require("modules/utils/utils")
local Cron = require("modules/utils/Cron")

carriage = {}

function carriage:new(metro)
	local o = {}

	o.metro = metro
	o.entityID = nil

	self.__index = self
   	return setmetatable(o, self)
end

function carriage:getEntity()
	if not self.entityID then return end
	return Game.FindEntityByID(self.entityID)
end

function carriage:spawn(data)
	if self.entityID then return end
	print("spawn", data.pos, data.rot)

	self.entityID = Game.GetDynamicEntitySystem():CreateEntity(DynamicEntitySpec.new({alwaysSpawned = true, recordID = "Vehicle.train", position = data.pos, rotation = data.rot}))
end

function carriage:despawn()
	local ent = self:getEntity()
	if not ent then return end

	ent:Dispose()
	self.entityID = nil
end

function carriage:setPosition(data)
	local ent = self:getEntity()
	if not ent then return end

	utils.tp(ent, utils.addVector(data.pos, Vector4.new(0, 0, 0.5, 0)), data.rot)
end

function carriage:handleAudio()

end

return carriage