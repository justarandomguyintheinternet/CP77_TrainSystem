local config = require("modules/utils/config")
local utils = require("modules/utils/utils")
local Cron = require("modules/utils/Cron")

objects = {
    entries = {},
    removalData = {},
    rmToDo = {},

    doors = {14623667433762366432ULL, 17785660048348043325ULL, 18152551121382210999ULL, 1637380487816572663ULL, 8255223377130512314ULL, --rep way north
             283370035515700666ULL, 13825642878604797175ULL, 10180697779767399351ULL, 9813806706733231677ULL, 6651814092147554784ULL, --ellison st
             821456880000517909ULL, 12110311706836548408ULL, 7110836648040637807ULL, 13381044026794042399ULL, 16956053804465631986ULL, --glen north
             15705056095356773324ULL, 2800463139005652945ULL, 7782450094505129069ULL, 17055156223622417486ULL, 4915933337779732199ULL, --congress
             9193886172035533538ULL, 6823456052343767283ULL, 15652140921899556937ULL, 9269767803950229077ULL, 5337313584294953832ULL} -- glen south
}

function objects.run()
    objects.handleEntries()
end

function objects.initialize()
    for _, file in pairs(dir("data/objects/entries")) do
        if file.name:match("^.+(%..+)$") == ".json" then
            table.insert(objects.entries, config.loadFile("data/objects/entries/" .. file.name))
        end
    end

    Cron.Every(2.0, function ()
        for _, i in ipairs (objects.doors) do
            local id = entEntityID.new({hash = i})
            if Game.FindEntityByID(id) ~= nil then
                Game.FindEntityByID(id):Dispose()
            end
        end
    end)
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
                if Game.FindEntityByID(id) then
                    exEntitySpawner.Despawn(Game.FindEntityByID(id))
                end
            end
            entry.ids = {}
        end
    end
end

function objects.despawnAll()
    for _, e in pairs(objects.entries) do
        for _, id in pairs(e.ids) do
            if Game.FindEntityByID(id) ~= nil then
                exEntitySpawner.Despawn(Game.FindEntityByID(id))
            end
        end
        e.ids = {}
    end
end

return objects