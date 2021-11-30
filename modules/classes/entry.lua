local config = require("modules/utils/config")
local utils = require("modules/utils/utils")

entry = {}

function entry:new()
	local o = {}

    o.center = Vector4.new(0, 0, 0, 0)
    o.radius = 0
    o.waypointPosition = Vector4.new(0, 0, 0, 0)
    o.useDoors = false
    o.stationID = 0

    o.elevatorPath = "base\\gameplay\\devices\\elevators\\appearances\\elevator_kitsch_a_jt_1_entrance_tv.ent"
    o.elevatorTime = 5
    o.elevatorPosition = Vector4.new(0, 0, 0, 0)
    o.elevatorPlayerRotation = EulerAngles.new(0, 0, 0)

    o.useSecondaryElevator = false
    o.secondaryPosition = Vector4.new(0, 0, 0, 0)

	self.__index = self
   	return setmetatable(o, self)
end

function entry:load(path)
    local data = config.loadFile(path)

    self.center = utils.getVector(data.center)
    self.radius = data.radius
    self.waypointPosition = utils.getVector(data.waypointPosition)
    self.useDoors = data.useDoors
    self.stationID = data.stationID

    self.elevatorPath = data.elevatorPath
    self.elevatorTime = data.elevatorTime
    self.elevatorPosition = utils.getVector(data.elevatorPosition)
    self.elevatorPlayerRotation = EulerAngles.new(0, 0, -90) -- Its always -90, idiot

    self.useSecondaryElevator = data.useSecondaryElevator or false
    self.secondaryPosition = data.secondaryPosition or Vector4.new(0, 0, 0, 0)
    self.secondaryPosition = utils.getVector(self.secondaryPosition)
end

function entry:save(path)
    local data = {}

    data.center = utils.fromVector(self.center)
    data.waypointPosition = utils.fromVector(self.waypointPosition)
    data.useDoors = self.useDoors
    data.radius = self.radius
    data.stationID = self.stationID
    data.elevatorPath = self.elevatorPath
    data.elevatorTime = self.elevatorTime
    data.elevatorPosition = utils.fromVector(self.elevatorPosition)
    data.elevatorPlayerRotation = utils.fromEuler(self.elevatorPlayerRotation)

    data.useSecondaryElevator = self.useSecondaryElevator or false
    data.secondaryPosition = self.secondaryPosition or Vector4.new(0, 0, 0, 0)
    data.secondaryPosition = utils.fromVector(data.secondaryPosition)

    config.saveFile(path, data)
end

return entry