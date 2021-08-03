-- Module for loading object files, mainly for entries and tracks, also for removing

local config = require("modules/utils/config")
local utils = require("modules/utils/utils")
local Cron = require("modules/utils/Cron")

objects = {
    entries = {},
    removalData = {},
    rmToDo = {}
}

function objects.run()
    objects.handleEntries()
    objects.updateRemoval()
end

function objects.initialize()
    for _, file in pairs(dir("data/objects/entries")) do
        if file.name:match("^.+(%..+)$") == ".json" then
            table.insert(objects.entries, config.loadFile("data/objects/entries/" .. file.name))
        end
    end

    local file = config.loadFile("data/objects/removal.json")
    for _, p in pairs(file) do
        table.insert(objects.removalData, utils.getVector(p))
    end
end

function objects.handleEntries()
    for _, entry in pairs(objects.entries) do
        if entry.ids == nil then entry.ids = {} end

        if utils.distanceVector(Game.GetPlayer():GetWorldPosition(), entry.pos) < entry.range and #entry.ids == 0 then
            for _, o in pairs(entry.objs) do
                local id = utils.spawnObject(o.path, utils.getVector(o.pos), utils.getEuler(o.rot):ToQuat())
                table.insert(entry.ids, id)
            end
        elseif utils.distanceVector(Game.GetPlayer():GetWorldPosition(), entry.pos) > entry.range + 2 and #entry.ids ~= 0 then
            for _, id in pairs(entry.ids) do
                Game.FindEntityByID(id):GetEntity():Destroy()
            end
            entry.ids = {}
        end
    end
end

function objects.updateRemoval()
    for _, id in pairs(objects.rmToDo) do
        if Game.FindEntityByID(id) ~= nil then
            Game.FindEntityByID(id):Dispose()
        else
            utils.removeItem(objects.rmToDo, id)
        end
    end
end

function objects.handleNewObject(obj)
    for _, p in pairs(objects.removalData) do
        if utils.isVector(p, obj:GetWorldPosition()) then
            table.insert(objects.rmToDo, obj:GetEntityID())
        end
    end
end

function objects.despawnAll()
    for _, e in pairs(objects.entries) do
        for _, id in pairs(e.ids) do
            Game.FindEntityByID(id):GetEntity():Destroy()
        end
    end
end

return objects