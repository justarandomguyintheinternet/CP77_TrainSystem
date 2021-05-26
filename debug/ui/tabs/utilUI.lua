utilUI = {
    despawnLevel = 2001
}

function utilUI.draw()
    utilUI.despawnLevel = ImGui.InputInt("Despawn Level", utilUI.despawnLevel)
    ImGui.SameLine()
    if ImGui.Button("Despawn") then
        Game.GetPreventionSpawnSystem():RequestDespawnPreventionLevel(utilUI.despawnLevel)
    end
end

return utilUI