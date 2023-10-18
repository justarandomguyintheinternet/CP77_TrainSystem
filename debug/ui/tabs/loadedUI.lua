loadedUI = {
    boxSize = {entry = {x = 530, y = 110}, station = {x = 530, y = 130}, track = {x = 530, y = 190}, line = {x = 530, y = 120}},
	colors = {entry = {0, 50, 255}, station = {0, 255, 0}, track = {255, 0, 0}, line = {255, 255, 0}},
    entries = {},
    stations = {},
    tracks = {},
    lines = {},
    CPS = require("CPStyling")
}

function loadedUI.update()
end

function loadedUI.draw(debug)
    for k, v in pairs(loadedUI.entries) do
        loadedUI.drawData(v, k, debug)
    end

    for k, v in pairs(loadedUI.stations) do
        loadedUI.drawData(v, k, debug)
    end

    for k, v in pairs(loadedUI.tracks) do
        loadedUI.drawData(v, k, debug)
    end

    for k, v in pairs(loadedUI.lines) do
        loadedUI.drawData(v, k, debug)
    end
end

function loadedUI.drawData(data, id, debug)
    local name = data.name
    local color = nil
    local size = {}
    local type = ""
    if data.waypointPosition ~= nil then
        color = loadedUI.colors.entry
        size = loadedUI.boxSize.entry
        type = "entries"
    elseif data.displayName ~= nil then
        color = loadedUI.colors.station
        size = loadedUI.boxSize.station
        type = "stations"
    elseif data.points ~= nil then
        color = loadedUI.colors.track
        size = loadedUI.boxSize.track
        type = "tracks"
    elseif data.stations ~= nil then
        color = loadedUI.colors.line
        size = loadedUI.boxSize.line
        type = "lines"
    end
    loadedUI.CPS.colorBegin("Border", color)
    loadedUI.CPS.colorBegin("Separator", color)
    ImGui.BeginChild("data_" .. id, size.x, size.y, true)

    data.name, changed =  ImGui.InputTextWithHint("Data Name", "Name...", data.name, 100)
    if changed then
        os.rename("data/" .. type .. "/" .. name .. ".json", "data/" .. type .. "/" .. data.name .. ".json")
    end

    ImGui.Separator()

    if type == "entries" then
        loadedUI.entry(data)
    elseif type == "stations" then
        loadedUI.station(data)
    elseif type == "tracks" then
        loadedUI.track(data)
    elseif type == "lines" then
        loadedUI.line(data)
    end

    ImGui.Separator()

    if ImGui.Button("Load to edit") then
        debug.baseUI.switchToEdit = true
        debug.baseUI.editUI.currentData = data
    end
    ImGui.SameLine()
    if ImGui.Button("Save") then
        data:save("data/" .. type .. "/" .. data.name .. ".json")
        debug.baseUI.fileUI[type][name] = nil
    end
    ImGui.SameLine()
    if ImGui.Button("Remove") then
        if debug.baseUI.editUI.currentData == data then
            debug.baseUI.editUI.currentData = nil
        end
        loadedUI[type][id] = nil
        debug.baseUI.editUI.deleteAllPins(data)
    end

    ImGui.EndChild()
    loadedUI.CPS.colorEnd(2)
end

function loadedUI.entry(data)
    ImGui.Text("Target Station ID: " .. data.stationID)
end

function loadedUI.station(data)
    ImGui.Text("Name: " .. data.displayName)
    ImGui.Text("ID: " .. data.id)
end

function loadedUI.track(data)
    ImGui.Text("ID: " .. data.id)
    ImGui.Text("Num points: " .. #data.points)
    ImGui.Text("Connected tracks (FIRST): back=" .. data.connectedID.first.back .. " | front=" .. data.connectedID.first.front)
    ImGui.Text("Connected tracks (SECOND): back=" .. data.connectedID.second.back .. " | front=" .. data.connectedID.second.front)
    ImGui.Text("Connected station: back=" .. data.station.back .. " | front=" .. data.station.front)
end

function loadedUI.line(data)
    ImGui.Text("Stations: " .. #data.stations)
end

return loadedUI