local CPS = require("CPStyling")
local config = require("modules/utils/config")
local utils = require("modules/utils/utils")

fileUI = {
    entries = {},
    stations = {},
    tracks = {},
    lines = {},
    boxSize = {entries = {x = 530, y = 90}, stations = {x = 530, y = 110}, tracks = {x = 530, y = 165}, lines = {x = 530, y = 100}},
	colors = {entries = {0, 50, 255}, stations = {0, 255, 0}, tracks = {255, 0, 0}, lines = {255, 255, 0}},
    filter = ""
}

function fileUI.drawFile(file, type, debug)
    local name = file.name:match("(.+)%..+$")

    if fileUI[type][name] == nil then
        print("loading " .. "data/" .. type .. "/" .. name .. ".json")
        fileUI[type][name] = config.loadFile("data/" .. type .. "/" .. name .. ".json") -- Load file if not loaded yet
    end

    CPS.colorBegin("Border", fileUI.colors[type])
    CPS.colorBegin("Separator", fileUI.colors[type])
    ImGui.BeginChild("file_" .. type .. name, fileUI.boxSize[type].x, fileUI.boxSize[type].y, true)

    ImGui.Text(name)
    ImGui.Separator()
    -- Type specific details

    if type == "entries" then
        fileUI.entry(fileUI[type][name])
    elseif type == "stations" then
        fileUI.station(fileUI[type][name])
    elseif type == "tracks" then
        fileUI.track(fileUI[type][name])
    elseif type == "lines" then
        fileUI.line(fileUI[type][name])
    end

    -- End type specific details
    if ImGui.Button("Load") then
        local class = nil
        if type == "entries" then
            class = require("modules/classes/entry"):new()
            class:load("data/" .. type .. "/" .. name .. ".json")
        elseif type == "stations" then
            class = require("modules/classes/station"):new()
            class:load("data/" .. type .. "/" .. name .. ".json")
        elseif type == "tracks" then
            class = require("modules/classes/track"):new()
            class:load("data/" .. type .. "/" .. name .. ".json")
        elseif type == "lines" then
            class = require("modules/classes/line"):new()
            class:load("data/" .. type .. "/" .. name .. ".json")
        end
        class.name = name
        debug.baseUI.loadedUI[type][math.random(1, 1000000)] = class
        debug.baseUI.switchToLoaded = true
    end
    ImGui.SameLine()
    if ImGui.Button("Delete File") then
        os.remove("data/" .. type .. "/" .. name .. ".json")
        fileUI[type][name] = nil
    end

    ImGui.EndChild()
    CPS.colorEnd(2)
end

function fileUI.entry(data)
    ImGui.Text("Target Station ID: " .. data.stationID)
end

function fileUI.station(data)
    ImGui.Text("Name: " .. data.displayName)
    ImGui.Text("ID: " .. data.id)
end

function fileUI.track(data)
    ImGui.Text("ID: " .. data.id)
    ImGui.Text("Num points: " .. #data.points)
    ImGui.Text("Connected tracks (FIRST): back=" .. data.connectedID.first.back .. " | front=" .. data.connectedID.first.front)
    ImGui.Text("Connected tracks (SECOND): back=" .. data.connectedID.second.back .. " | front=" .. data.connectedID.second.front)
    ImGui.Text("Connected station: back=" .. data.station.back .. " | front=" .. data.station.front)
end

function fileUI.line(data)
    ImGui.Text("Stations: " .. #data.stations)
end

function fileUI.draw(debug)
    fileUI.filter = ImGui.InputTextWithHint('##Filter', 'Search for file...', fileUI.filter, 10)

    if fileUI.filter ~= '' then
        ImGui.SameLine()
        if ImGui.Button('X') then
            fileUI.filter = ''
        end
    end

    state = ImGui.CollapsingHeader("Entries")
    if state then
        ImGui.PushID("headerEntries")
        for _, file in pairs(dir("data/entries")) do
            if file.name:match("^.+(%..+)$") == ".json" then
                if (file.name:lower():match(fileUI.filter:lower())) ~= nil then
                    fileUI.drawFile(file, "entries", debug)
                end
            end
        end
        ImGui.PopID()
    end

    state = ImGui.CollapsingHeader("Stations")
    if state then
        ImGui.PushID("headerStations")
        for _, file in pairs(dir("data/stations")) do
            if file.name:match("^.+(%..+)$") == ".json" then
                if (file.name:lower():match(fileUI.filter:lower())) ~= nil then
                    fileUI.drawFile(file, "stations", debug)
                end
            end
        end
        ImGui.PopID()
    end

    state = ImGui.CollapsingHeader("Tracks")
    if state then
        ImGui.PushID("headerTracks")
        for _, file in pairs(dir("data/tracks")) do
            if file.name:match("^.+(%..+)$") == ".json" then
                if (file.name:lower():match(fileUI.filter:lower())) ~= nil then
                    fileUI.drawFile(file, "tracks", debug)
                end
            end
        end
        ImGui.PopID()
    end

    state = ImGui.CollapsingHeader("Lines")
    if state then
        ImGui.PushID("headerLines")
        for _, file in pairs(dir("data/lines")) do
            if file.name:match("^.+(%..+)$") == ".json" then
                if (file.name:lower():match(fileUI.filter:lower())) ~= nil then
                    fileUI.drawFile(file, "lines", debug)
                end
            end
        end
        ImGui.PopID()
    end
end

return fileUI