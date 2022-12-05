--[[
I18n.lua
Internationalization Manager

Copyright (c) 2022 llicursi
]]

local I18N = { version = "1.0.1" }

---@class LanguageOption
local LanguageOption = {
    VoiceOver = 1,
    Subtitles = 2,
    OnScreen = 3
}

---@param languageOption Int32
---@return String
local function GetCurrentLanguage(languageOption)
    local Settings = Game.GetSettingsSystem():GetRootGroup():GetGroups(true)
    local Languages = Settings[6]:GetVars(true)
    return Languages[languageOption]:GetValue().value
end

---@param basename String
---@param lang String|nil
---@return table
local function LoadLanguageFile(basename, lang)
    local fileName = string.lower(basename) .. (lang and "." .. lang or "") .. ".json"
    -- print("[I18N] Loading data/i18n/" .. fileName)
    local file = io.open("data/i18n/" .. fileName, "r")
    if file then
        local config = json.decode(file:read("*a"))
        file:close()
        return config
    end
    return { Entries = {} }
end

local settingsLanguage = {}
local options = {}
-- Loads the configurations when Game is available
function I18N.Load()
    for name, index in pairs(LanguageOption) do
        settingsLanguage[index] = GetCurrentLanguage(index)
        options[index] = {
            default = LoadLanguageFile(name),
            lang = LoadLanguageFile(name, settingsLanguage[index])
        }
    end
end

---@param languageLibrary any
---@param langKey String
---@return String|nil
local function GetI18NValue(languageLibrary, langKey)
    return languageLibrary and languageLibrary[langKey] or nil
end

---@param langKey String
---@return String 
local function GetCurrLangOrDefault(languageOption, langKey)
    if options == nil or next(options) == nil then
        if Game then
            I18N.Load()
        else 
            return langKey
        end
    end
    local i18nValue = GetI18NValue(options[languageOption].lang, langKey)
    if not i18nValue then
        -- Checks default language
        i18nValue = GetI18NValue(options[languageOption].default, langKey)
    else 
        print("[I18N] GetCurrLangOrDefault(".. languageOption.."," .. langKey..")" )
    end
    return i18nValue and i18nValue or langKey
end

---@return String "en, es, pt-br, ..."
function I18N.GetVoiceOverLanguage()
    return settingsLanguage[LanguageOption.VoiceOver]
end

---@return String "en, es, pt-br, ..."
function I18N.GetSubtitlesLanguage()
    return settingsLanguage[LanguageOption.Subtitles]
end

---@return String "en, es, pt-br, ..."
function I18N.GetOnScreenLanguage()
    return settingsLanguage[LanguageOption.OnScreen]
end

---Gets internationalized value of given key for On Screen language defined on settings.<br>
---If i18n is not found, the default language of the mod will be used or "Unknown" will be printed
---@param langKey String
---@return String
function I18N.OnScreen(langKey)
    return GetCurrLangOrDefault(LanguageOption.OnScreen, langKey)
end

---Gets internationalized value of given key for Subtitles language defined on settings.<br>
---If i18n is not found, the default language of the mod will be used or "Unknown" will be printed
---@param langKey String
---@return String
function I18N.Subtitles(langKey)
    return GetCurrLangOrDefault(LanguageOption.Subtitles, langKey)
end

---Gets internationalized value of given key for Voice Over language defined on settings.<br>
---If i18n is not found, the default language of the mod will be used or "Unknown" will be printed
---@param langKey String Key to be 
---@return String
function I18N.VoiceOver(langKey)
    return GetCurrLangOrDefault(LanguageOption.VoiceOver, langKey)
end

return I18N
