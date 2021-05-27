local station = require("modules/classes/station")
local Cron = require("modules/utils/Cron")
local utils = require("modules/utils/utils")

stationSys = {}

function stationSys:new(ts)
	local o = {}

	o.ts = ts
	o.stations = {}
	o.onStation = false
	o.currentStation = nil

	self.__index = self
   	return setmetatable(o, self)
end

function stationSys:load()
	for _, file in pairs(dir("data/stations")) do
        if file.name:match("^.+(%..+)$") == ".json" then
            local s = station:new()
            s:load("data/stations/" .. file.name)
            self.stations[s.id] = s
        end
    end
end

function stationSys:enter(id)
	self.currentStation = self.stations[id]
	self.ts.observers.noSave = true
	Cron.After(0.3, function ()
		self.currentStation:tpTo(self.currentStation.portalPoint)
	end)
	Cron.After(0.32, function ()
		self.currentStation:spawn() -- Spawn AFTER start of tp, or it crashes when getting a loading screen, but only little bit after to make sure stuff spawns even if there is no loading screen
	end)

	if #self.currentStation.objects ~= 0 then
		local cam = Game.GetPlayer():GetFPPCameraComponent()
		cam.pitchMin = 100

		Cron.After(0.5, function ()
			local cam = Game.GetPlayer():GetFPPCameraComponent()
			cam:ResetPitch()
		end)
	end

	utils.togglePin(self, "exit", true, Vector4.new(self.currentStation.portalPoint.pos.x, self.currentStation.portalPoint.pos.y, self.currentStation.portalPoint.pos.z + 1, 0), "GetInVariant") --DistractVariant
	Game.ApplyEffectOnPlayer("GameplayRestriction.NoCombat")
	Game.ChangeZoneIndicatorSafe()

	self.ts.trackSys:requestTrainToStation(self.currentStation)
end

function stationSys:leave()

end

function stationSys:update()
	if self.currentStation then
		self.currentStation:update()
		if not self.currentStation:inStation() then
			self.currentStation:tpTo(self.currentStation.portalPoint)
		end
		if self.currentStation:nearExit() then
			self.ts.hud.drawExit()
			if self.ts.input.interactKey then
                self.ts.input.interactKey = false
				utils.togglePin(self, "exit", false)
                self.currentStation:exitToGround(self.ts)
				self.currentStation = nil
            end
		end
	end
end

return stationSys