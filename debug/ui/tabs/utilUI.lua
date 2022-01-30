utilUI = {
    despawnLevel = 2001,
    sticky = false,
    target = nil,
    speedUp = false,
    speed = 5,
    busOffset = 2
}

function utilUI.draw()
    utilUI.despawnLevel = ImGui.InputInt("Despawn Level", utilUI.despawnLevel)
    ImGui.SameLine()
    if ImGui.Button("Despawn") then
        Game.GetPreventionSpawnSystem():RequestDespawnPreventionLevel(utilUI.despawnLevel)
    end

    ImGui.Separator()

    if ImGui.Button("Set Sticky Target") then
        utilUI.target = Game.GetTargetingSystem():GetLookAtObject(Game.GetPlayer(), false, false)
    end
    utilUI.sticky = ImGui.Checkbox("Sticky Player", utilUI.sticky)
    ImGui.SameLine()
    ImGui.Text(tostring(utilUI.target))

    ImGui.Separator()
    utilUI.speedUp, changed = ImGui.Checkbox("Speed up time", utilUI.speedUp)
    if changed then
        if utilUI.speedUp then
            Game.SetTimeDilation(utilUI.speed)
        else
            Game.SetTimeDilation(0)
        end
    end
    ImGui.SameLine()
    utilUI.speed, changed = ImGui.InputInt("Speed Mult.", utilUI.speed)
    if changed and utilUI.speedUp then
        Game.SetTimeDilation(utilUI.speed)
    end

    utilUI.busOffset, changed = ImGui.DragFloat("Bus offset", utilUI.busOffset, 0.02, -9999, 9999, "%.2f")
end

function utilUI.update()
    if utilUI.sticky and utilUI.target then
        local pos = utilUI.target:GetWorldPosition()
        pos.z = pos.z + 3.5
        Game.GetTeleportationFacility():Teleport(GetPlayer(), pos,  utilUI.target:GetWorldOrientation():ToEulerAngles())
    end
end

return utilUI