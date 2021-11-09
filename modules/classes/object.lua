local utils = require("modules/utils/utils")
local Cron = require("modules/utils/Cron")

object = {}

function object:new(level, station)
	local o = {}

    o.spawned = false
    o.entID = nil
    o.entity = nil
    o.level = level

    o.frozen = true
    o.invincible = true
    o.pos = Vector4.new(0, 0, 0, 0)
    o.rot = Quaternion.new(0.001, 0, 0, 0)
    o.name = ""
    o.app = ""
    o.radioStation = station or 0

    o.id = math.random(1, 100000) -- Id for imgui child

	self.__index = self
   	return setmetatable(o, self)
end

function object:spawn()
    local transform = Game.GetPlayer():GetWorldTransform()
    transform.SetPosition(transform, self.pos) --transform.SetPosition(transform, self.pos) for next cet
    transform.SetOrientation(transform, self.rot) --transform.SetOrientation(transform, self.rot)
    self.entID = Game.GetPreventionSpawnSystem():RequestSpawn(TweakDBID.new(self.name), self.level, transform)

    Cron.Every(0.25, {tick = 0}, function(timer)
        self.entity = Game.FindEntityByID(self.entID)
        print("try spawn", self.name)
        if self.entity ~= nil then
			timer:Halt()
            self.spawned = true
            if self.app ~= "" then
                self.entity:PrefetchAppearanceChange(self.app)
                self.entity:ScheduleAppearanceChange(self.app)
            end
            utils.setRadioStation(self.entity, self.radioStation)
		end
	end)
end

function object:godMode()
    if self.invincible then
        local vComp = self.entity:GetVehicleComponent()
        self.entity:DestructionResetGrid()
        self.entity:DestructionResetGlass()
        vComp:RepairVehicle()
        Game.GetGodModeSystem():AddGodMode(self.entity:GetEntityID(), 0, "")
    else
        Game.GetGodModeSystem():RemoveGodMode(self.entity:GetEntityID(), 0, "")
    end
end

function object:update() -- Required to run each frame for frozen and invincible to work
    local ent = Game.FindEntityByID(self.entID)
    if ent == nil then self.spawned = false end

    if self.spawned then
        if self.frozen then
            Game.GetTeleportationFacility():Teleport(self.entity, self.pos,  GetSingleton('Quaternion'):ToEulerAngles(self.rot))
        end
        self:godMode()
        self.entity:GetVehicleComponent():DestroyMappin()
    end
end

function object:despawn()
    Game.GetPreventionSpawnSystem():RequestDespawnPreventionLevel(self.level)
    --self.spawned = false
end

function object:respawn()
    self:despawn()
    Cron.Every(0.01, {tick = 0}, function(timer)
        self.entity = Game.FindEntityByID(self.entID)
        if self.entity == nil then
			timer:Halt()
            self:spawn()
            print("new spawned")
		end
	end)
end

function object:load(data)
    self.frozen = data.frozen
    self.invincible = data.invincible
    self.name = data.name
    self.app = data.app
    self.pos = utils.getVector(data.pos)
    self.rot = utils.getQuaternion(data.rot)
end

function object:getData()
    local data = {}

    data.frozen = self.frozen
    data.invincible = self.invincible
    data.name = self.name
    data.app = self.app
    data.pos = utils.fromVector(self.pos)
    data.rot = utils.fromQuaternion(self.rot)

    return data
end

return object