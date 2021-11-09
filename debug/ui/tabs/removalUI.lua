local config = require("modules/utils/config")
local utils = require("modules/utils/utils")

rmUI = {
    data = nil
}

function rmUI.draw()
    if rmUI.data == nil then
        rmUI.data = {}
        local file = config.loadFile("data/objects/removal.json")
        for _, p in pairs(file) do
            table.insert(rmUI.data, p)
        end
    end

    if ImGui.Button("Add look at") then
        local target = Game.GetTargetingSystem():GetLookAtObject(Game.GetPlayer(), false, true)
        if target then
            table.insert(rmUI.data, tostring(target:GetEntityID().hash))
            target:Dispose()
            rmUI.save()
        end
    end

    ImGui.Separator()

    for _, p in pairs(rmUI.data) do
        ImGui.Text(tostring(p))
        ImGui.SameLine()
        ImGui.PushID(tostring(p))
        if ImGui.Button("Delete") then
            utils.removeItem(rmUI.data, p)
            rmUI.save()
        end

        ImGui.SameLine()
        if ImGui.Button("Copy hash string to clipboard") then
            ImGui.SetClipboardText(tostring(p .. ", "))
        end
        ImGui.PopID()
        -- if ImGui.Button("TP To") then
        --     Game.GetTeleportationFacility():Teleport(Game.GetPlayer(), p, Game.GetPlayer():GetWorldOrientation():ToEulerAngles())
        -- end
    end
end

function rmUI.save()
    local toSave = {}
    for _, p in pairs(rmUI.data) do
        table.insert(toSave, p)
    end
    config.saveFile("data/objects/removal.json", toSave)
end

return rmUI