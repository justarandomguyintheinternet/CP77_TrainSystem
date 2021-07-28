local config = require("modules/utils/config")

settings = {}

function settings.draw(ts)
    ts.CPS:setThemeBegin()
    ImGui.Begin("Train System Config", ImGuiWindowFlags.AlwaysAutoResize)

    ImGui.Text("Default Radio Station:")
    if ImGui.RadioButton("No Radio", ts.settings.defaultStation == -1) then
        ts.settings.defaultStation = -1
        config.saveFile("data/config.json", ts.settings)
    end
    if ImGui.RadioButton("Radio Vexelstrom", ts.settings.defaultStation == 0) then
        ts.settings.defaultStation = 0
        config.saveFile("data/config.json", ts.settings)
    end
    if ImGui.RadioButton("Night FM", ts.settings.defaultStation == 1) then
        ts.settings.defaultStation = 1
        config.saveFile("data/config.json", ts.settings)
    end
    if ImGui.RadioButton("The Dirge", ts.settings.defaultStation == 2) then
        ts.settings.defaultStation = 2
        config.saveFile("data/config.json", ts.settings)
    end
    if ImGui.RadioButton("Radio Pebkac", ts.settings.defaultStation == 3) then
        ts.settings.defaultStation = 3
        config.saveFile("data/config.json", ts.settings)
    end
    if ImGui.RadioButton("Pacific Dreams", ts.settings.defaultStation == 4) then
        ts.settings.defaultStation = 4
        config.saveFile("data/config.json", ts.settings)
    end
    if ImGui.RadioButton("Morro Rock Radio", ts.settings.defaultStation == 5) then
        ts.settings.defaultStation = 5
        config.saveFile("data/config.json", ts.settings)
    end
    if ImGui.RadioButton("Body Heat Radio", ts.settings.defaultStation == 6) then
        ts.settings.defaultStation = 6
        config.saveFile("data/config.json", ts.settings)
    end
    if ImGui.RadioButton("30 Principales", ts.settings.defaultStation == 7) then
        ts.settings.defaultStation = 7
        config.saveFile("data/config.json", ts.settings)
    end
    if ImGui.RadioButton("Ritual FM", ts.settings.defaultStation == 8) then
        ts.settings.defaultStation = 8
        config.saveFile("data/config.json", ts.settings)
    end
    ImGui.Separator()

    ImGui.End()
    ts.CPS:setThemeEnd()
end

return settings