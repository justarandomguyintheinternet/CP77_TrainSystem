createUI = {
    name = "",
    selectedData = 0
}

function createUI.draw(debug)
    createUI.selectedData = ImGui.Combo("Data Type", createUI.selectedData, {"Entry", "Station", "Track"}, 3)
    createUI.name =  ImGui.InputTextWithHint("Data Name", "Name...", createUI.name, 100)
    if ImGui.Button("Create") then
        local data = nil
        if createUI.selectedData == 0 then
            data = require("modules/classes/entry"):new()
            data.name = createUI.name
            debug.baseUI.loadedUI.entries[math.random(1, 100000000)] = data
            data:save("data/entries/" .. data.name .. ".json")
        elseif createUI.selectedData == 1 then
            data = require("modules/classes/station"):new()
            data.name = createUI.name
            debug.baseUI.loadedUI.stations[math.random(1, 100000000)] = data
            data:save("data/stations/" .. data.name .. ".json")
        elseif createUI.selectedData == 2 then
            data = require("modules/classes/track"):new()
            data.name = createUI.name
            debug.baseUI.loadedUI.tracks[math.random(1, 100000000)] = data
            data:save("data/tracks/" .. data.name .. ".json")
        end
        createUI.name = ""
    end
end

return createUI