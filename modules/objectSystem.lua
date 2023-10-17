local Cron = require("modules/utils/Cron")

local objects = {
    doors = {
                14623667433762366432ULL, 17785660048348043325ULL, 18152551121382210999ULL, 1637380487816572663ULL, 8255223377130512314ULL, --rep way north
                283370035515700666ULL, 13825642878604797175ULL, 10180697779767399351ULL, 9813806706733231677ULL, 6651814092147554784ULL, --ellison st
                821456880000517909ULL, 12110311706836548408ULL, 7110836648040637807ULL, 13381044026794042399ULL, 16956053804465631986ULL, --glen north
                15705056095356773324ULL, 2800463139005652945ULL, 7782450094505129069ULL, 17055156223622417486ULL, 4915933337779732199ULL, --congress
                9193886172035533538ULL, 6823456052343767283ULL, 15652140921899556937ULL, 9269767803950229077ULL, 5337313584294953832ULL -- glen south
            },
}

-- Start Cron loop, that removes unwanted objects like doors
function objects.initialize()
    Cron.Every(1.0, function ()
        for _, hash in ipairs (objects.doors) do
            local object = Game.FindEntityByID(entEntityID.new({hash = hash}))
            if object ~= nil then
                pcall(function () -- You never know...
                    object:Dispose()
                end)
            end
        end
    end)
end

return objects