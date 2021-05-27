local CPS = require("CPStyling")
local config = require("modules/utils/config")
local utils = require("modules/utils/utils")

fileUI = {
    entries = {},
    stations = {},
    tracks = {},
    boxSize = {entries = {x = 530, y = 75}, stations = {x = 530, y = 90}, tracks = {x = 530, y = 145}},
	colors = {entries = {0, 50, 255}, stations = {0, 255, 0}, tracks = {255, 0, 0}},
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
    ImGui.Text("Connected tracks (FIRST): next=" .. data.connectedID.first.next .. " | last=" .. data.connectedID.first.last)
    ImGui.Text("Connected tracks (SECOND): next=" .. data.connectedID.second.next .. " | last=" .. data.connectedID.second.last)
    ImGui.Text("Connected station: next=" .. data.hasStation.next .. " | last=" .. data.hasStation.last)
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
end

return fileUI