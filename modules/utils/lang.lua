local lang = {}

function lang.getLang(key)
    local language = Game.GetSettingsSystem():GetVar("/language", "OnScreen"):GetValue().value
    local loc = require("localization/" .. language)

    if loc[key] == "" then
        return "en-us"
    else
        return language
    end
end

function lang.getText(key)
    local language = lang.getLang(key)
    local loc = require("localization/" .. language)
    local text = loc[key]

    if text == "" or nil then
        return "Not Localized"
    else
        return text
    end
end

return lang