local utils = require("modules/utils/utils")
local object = require("modules/classes/object")
local point = require("modules/classes/point")
local CPS = require("CPStyling")
local Cron = require("modules/utils/Cron")

editUI = {
    currentData = nil,
    mappins = {},
    pinsState = {},
    color = {0, 50, 255},
    box = {object = {x = 650, y = 215}, point = {x = 450, y = 255}},
    type = "",

    timeStop = false,
    skipAmount = 0.1,
    autoPlace = false,
    addAtFrame = false,
    newPointOffset = nil
}

function editUI.draw(debug)
    if editUI.currentData ~= nil then
        if editUI.currentData.waypointPosition ~= nil then
            editUI.type = "entry"
            editUI.drawEntry()
        elseif editUI.currentData.displayName ~= nil then
            editUI.type = "station"
            editUI.drawStation()
        elseif editUI.currentData.points ~= nil then
            editUI.type = "track"
            editUI.drawTrack()
        end
    end
end

function editUI.drawEntry()
    local entry = editUI.currentData

    entry.stationID = ImGui.InputInt('StationID', entry.stationID)

    entry.useDoors = ImGui.Checkbox("Use doors", entry.useDoors)

    entry.radius = ImGui.InputFloat('Radius', entry.radius, 0, 100, "%.2f")
    local dist = utils.distanceVector(entry.center, Game.GetPlayer():GetWorldPosition())
    ImGui.Text("Current distance to center: " .. tonumber(string.format("%.2f", dist)))

    ImGui.Text("Center: " .. tostring(entry.center))
    ImGui.SameLine()
    if ImGui.Button("Set to player pos") then
        entry.center = Game.GetPlayer():GetWorldPosition()
    end
    ImGui.SameLine()
    editUI.drawPinBox("Pin", entry, "center", entry.center)

    ImGui.Text("Waypoint: " .. tostring(entry.waypointPosition))
    ImGui.SameLine()
    ImGui.PushID("waypoint")
    if ImGui.Button("Set to player pos") then
        entry.waypointPosition = Game.GetPlayer():GetWorldPosition()
    end
    ImGui.PopID()
    ImGui.SameLine()
    editUI.drawPinBox("Pin", entry, "waypoint", entry.waypointPosition)

    if ImGui.Button("TP to center") then
        Game.GetTeleportationFacility():Teleport(Game.GetPlayer(), entry.waypointPosition, EulerAngles.new(0, 0, 0))
    end

    entry.elevatorPath = ImGui.InputTextWithHint("Elevator Path", "Path...", entry.elevatorPath, 100)
    entry.elevatorTime = ImGui.InputFloat('Elevator Time', entry.elevatorTime, 0, 100, "%.1f")
    if ImGui.Button("Set Elevator Position") then
        entry.elevatorPosition = Game.GetPlayer():GetWorldPosition()
    end
    ImGui.SameLine()
    if ImGui.Button("Set Elevator Player Rotation") then
        entry.elevatorPlayerRotation = Game.GetPlayer():GetWorldOrientation():ToEulerAngles()
    end
    ImGui.SameLine()
    if ImGui.Button("TP to") then
        Game.GetTeleportationFacility():Teleport(Game.GetPlayer(), entry.elevatorPosition,  entry.elevatorPlayerRotation)
    end

    if ImGui.Button("Spawn") then
        entry.elevatorID = utils.spawnObject(entry.elevatorPath, entry.elevatorPosition, EulerAngles.new(0, 0, 0):ToQuat())
    end
    ImGui.SameLine()
    if ImGui.Button("Despawn") then
        if entry.elevatorID ~= nil then Game.FindEntityByID(entry.elevatorID):GetEntity():Destroy() end
    end

    ImGui.Separator()
    entry.useSecondaryElevator = ImGui.Checkbox("Use secondary Elevator", entry.useSecondaryElevator)
    if entry.useSecondaryElevator then
        if ImGui.Button("Set secondary Elevator Position") then
            entry.secondaryPosition = Game.GetPlayer():GetWorldPosition()
        end
        ImGui.SameLine()
        if ImGui.Button("TP to 2") then
            Game.GetTeleportationFacility():Teleport(Game.GetPlayer(), entry.secondaryPosition,  entry.elevatorPlayerRotation)
        end
    end
end

function editUI.drawStation()
    local station = editUI.currentData
-- DisplayName
    station.displayName =  ImGui.InputTextWithHint("Display Name", "Name...", station.displayName, 100)
-- ID
    station.id = ImGui.InputInt('ID', station.id)
-- Radius
    station.radius = ImGui.InputFloat('Radius', station.radius, 0, 100, "%.2f")
    local dist = utils.distanceVector(station.center, Game.GetPlayer():GetWorldPosition())
    ImGui.Text("Current distance to center: " .. tonumber(string.format("%.2f", dist)))

    station.minZ = ImGui.InputFloat('Min Z', station.minZ, 0, 500, "%.1f")
    local distZ = utils.distanceVector(utils.subVector(Game.GetPlayer():GetWorldPosition(), Vector4.new(0, 0, Game.GetPlayer():GetWorldPosition().z - station.minZ, 0)), Game.GetPlayer():GetWorldPosition())
    ImGui.Text("Current distance to Z: " .. tonumber(string.format("%.2f", distZ)))

    station.spawnOffset = ImGui.InputFloat('Train Spawn Offset', station.spawnOffset, -100, 100, "%.1f")

    station.holdTime = ImGui.InputFloat('Hold Time', station.holdTime, -100, 100, "%.1f")
-- Doors
    station.useDoors = ImGui.Checkbox("Use doors", station.useDoors)
-- Center
    ImGui.Separator()
    ImGui.Text("Center: ")
    ImGui.SameLine()
    if ImGui.Button("Set to player pos") then
        station.center = Game.GetPlayer():GetWorldPosition()
    end
    ImGui.SameLine()
    editUI.drawPinBox("Pin", station, "center", station.center)
-- Train Exit
    ImGui.Text("Train Exit:")
    ImGui.SameLine()
    ImGui.PushID("exit")
    if ImGui.Button("Set to player") then
        station.trainExit.pos = Game.GetPlayer():GetWorldPosition()
        station.trainExit.rot = Game.GetPlayer():GetWorldOrientation()
    end
    ImGui.PopID()
    ImGui.SameLine()
    editUI.drawPinBox("Pin", station, "exit", station.trainExit.pos)
    ImGui.SameLine()
    if ImGui.Button("TP to exit") then
        Game.GetTeleportationFacility():Teleport(Game.GetPlayer(), station.trainExit.pos,  station.trainExit.rot:ToEulerAngles())
    end
-- Portal
    ImGui.Text("PortalPoint:")
    ImGui.SameLine()
    ImGui.PushID("portal")
    if ImGui.Button("Set to player") then
        station.portalPoint.pos = Game.GetPlayer():GetWorldPosition()
        station.portalPoint.rot = Game.GetPlayer():GetWorldOrientation()
    end
    ImGui.PopID()
    ImGui.SameLine()
    editUI.drawPinBox("Pin", station, "portal", station.portalPoint.pos)
    ImGui.SameLine()
    if ImGui.Button("TP to portal") then
        Game.GetTeleportationFacility():Teleport(Game.GetPlayer(), station.portalPoint.pos,  station.portalPoint.rot:ToEulerAngles())
    end
-- Ground
    ImGui.Text("GroundPoint:")
    ImGui.SameLine()
    ImGui.PushID("ground")
    if ImGui.Button("Set to player") then
        station.groundPoint.pos = Game.GetPlayer():GetWorldPosition()
        station.groundPoint.rot = Game.GetPlayer():GetWorldOrientation()
    end
    ImGui.PopID()
    ImGui.SameLine()
    editUI.drawPinBox("Pin", station, "ground", station.groundPoint.pos)
    ImGui.SameLine()
    if ImGui.Button("TP to ground") then
        Game.GetTeleportationFacility():Teleport(Game.GetPlayer(), station.groundPoint.pos,  station.groundPoint.rot:ToEulerAngles())
    end
-- Objects
    ImGui.Separator()
    station.objectFileName = ImGui.InputTextWithHint("Objects File Name", "Name...", station.objectFileName, 100)
    if ImGui.Button("Set Exit Door") then
        station.exitDoorPosition = Game.GetTargetingSystem():GetLookAtObject(Game.GetPlayer(), false, true):GetWorldPosition()
    end
    station.exitDoorSealed = ImGui.Checkbox("Exit Door Sealed", station.exitDoorSealed)

    if ImGui.Button("Spawn") then
        station:spawn()
    end
    ImGui.SameLine()
    if ImGui.Button("Despawn") then
        station:despawn()
    end
end

function editUI.drawTrack()
    local track = editUI.currentData
-- Setup tmp variables
    if track.currentPointID == nil then track.currentPointID = 1 end
    if track.target == nil then track.target = nil end -- lol?
    if track.trainObj == nil then
        track.trainObj = object:new(1999)
        track.trainObj.name = "Vehicle.av_public_train_b"
    end
-- ID
    track.id = ImGui.InputInt("ID", track.id)
    ImGui.Separator()
-- Timeline
    track.currentPointID, changed = ImGui.SliderInt("Current Point ID", track.currentPointID, 1, #track.points)

    if ImGui.Button("Point Back") then
        track.currentPointID = track.currentPointID - 1
        track.currentPointID = math.max(1, (math.min(track.currentPointID, #track.points)))
    end
    ImGui.SameLine()
    if ImGui.Button("Point Forward") then
        track.currentPointID = track.currentPointID + 1
        track.currentPointID = math.max(1, (math.min(track.currentPointID, #track.points)))
    end

    ImGui.Separator()
-- Meta info
    local state = ImGui.CollapsingHeader("Connected Settings")
    if state then
        ImGui.Text("Connected IDs: (-1 is not connected / false)")
        ImGui.PushID("connectedIDFIRST")
        ImGui.Text("FIRST:")
        track.connectedID.first.last = ImGui.InputInt('LAST', track.connectedID.first.last)
        track.connectedID.first.next = ImGui.InputInt('NEXT', track.connectedID.first.next)
        ImGui.Separator()
        ImGui.Text("SECOND:")
        ImGui.PopID()
        ImGui.PushID("connectedIDSECOND")
        track.connectedID.second.last = ImGui.InputInt('LAST', track.connectedID.second.last)
        track.connectedID.second.next = ImGui.InputInt('NEXT', track.connectedID.second.next)
        ImGui.Separator()
        ImGui.PopID()
        ImGui.Text("Has Station: ")
        track.hasStation.last = ImGui.InputInt('LAST', track.hasStation.last)
        track.hasStation.next = ImGui.InputInt('NEXT', track.hasStation.next)
    end

    ImGui.Separator()
-- Time speed/skip
    editUI.timeStop, changed = ImGui.Checkbox("Stop Time", editUI.timeStop)
    if changed then
        if editUI.timeStop then
            Game.GetTimeSystem():SetIgnoreTimeDilationOnLocalPlayerZero(true)
            Game.SetTimeDilation(0.0000000000001)
        else
            Game.GetTimeSystem():SetIgnoreTimeDilationOnLocalPlayerZero(false)
            Game.SetTimeDilation(0)
        end
    end
    ImGui.SameLine()

    if editUI.newPointOffset == nil then
        editUI.newPointOffset = Vector4.new(0, 0, 0, 0)
    end

    if ImGui.Button("Skip") then
        Game.SetTimeDilation(0)
        Cron.After(editUI.skipAmount, function ()
            Game.SetTimeDilation(0.0000000000001)
            if editUI.autoPlace then
                if track.target ~= nil then
                    local p = point:new()
                    p.pos = track.target:GetWorldPosition()
                    p.pos = utils.addVector(p.pos, editUI.newPointOffset)
                    p.rot = track.target:GetWorldOrientation()
                    if editUI.addAtFrame then
                        table.insert(track.points, track.currentPointID, p)
                    else
                        table.insert(track.points, p)
                    end
                end
            end
        end)
    end
    ImGui.SameLine()
    editUI.skipAmount = ImGui.InputFloat("Amount", editUI.skipAmount, 0, 1, "%.2f")

    ImGui.Separator()
-- Target
    if ImGui.Button("Set target look") then
        track.target = Game.GetTargetingSystem():GetLookAtObject(Game.GetPlayer(), false, false)
    end
    ImGui.SameLine()
    if ImGui.Button("Set target player") then
        track.target = Game.GetPlayer()
    end
    ImGui.SameLine()
    ImGui.Text("Target: ".. tostring(track.target))

    ImGui.Separator()
-- Spawn train
    if ImGui.Button("Spawn train") then
        track.trainObj.pos = track.points[track.currentPointID].pos
        track.trainObj.rot = track.points[track.currentPointID].rot
        track.trainObj:spawn()
    end
    ImGui.SameLine()
    if ImGui.Button("Despawn train") then
        track.trainObj:despawn()
    end

    if #track.points ~= 0 then
        track.trainObj.pos = track.points[track.currentPointID].pos
        track.trainObj.rot = track.points[track.currentPointID].rot
    end

    ImGui.Separator()
-- Add
    if ImGui.Button("Add point") then
        if track.target ~= nil then
            local p = point:new()
            p.pos = track.target:GetWorldPosition()
            p.pos = utils.addVector(p.pos, editUI.newPointOffset)
            p.rot = track.target:GetWorldOrientation()
            if editUI.addAtFrame then
                table.insert(track.points, track.currentPointID, p)
            else
                table.insert(track.points, p)
            end
        end
    end
    ImGui.SameLine()
    editUI.autoPlace = ImGui.Checkbox("Auto place", editUI.autoPlace)
    ImGui.SameLine()
    editUI.addAtFrame = ImGui.Checkbox("Place on current frame", editUI.addAtFrame)

    ImGui.PushItemWidth(100)
    editUI.newPointOffset.x = ImGui.DragFloat("##xx", editUI.newPointOffset.x, 0.01, -9999, 9999, "%.3f X")
    ImGui.SameLine()
    editUI.newPointOffset.y = ImGui.DragFloat("##yy", editUI.newPointOffset.y, 0.01, -9999, 9999, "%.3f Y")
    ImGui.SameLine()
    editUI.newPointOffset.z = ImGui.DragFloat("##zz", editUI.newPointOffset.z, 0.01, -9999, 9999, "%.3f Z")
    ImGui.PopItemWidth()
    ImGui.SameLine()
    ImGui.Text("New Point Offset")
-- Points
    if #track.points ~= 0 then
        editUI.drawPoint(track.points[track.currentPointID], track)
    end
end

function editUI.drawPoint(point, track)
    CPS.colorBegin("Border", editUI.color)
    ImGui.BeginChild("point", editUI.box.point.x, editUI.box.point.y, true)

-- Position
    ImGui.PushItemWidth(100)
    point.pos.x = ImGui.DragFloat("##x", point.pos.x, 0.01, -9999, 9999, "%.3f X")
    ImGui.SameLine()
    point.pos.y = ImGui.DragFloat("##y", point.pos.y, 0.01, -9999, 9999, "%.3f Y")
    ImGui.SameLine()
    point.pos.z = ImGui.DragFloat("##z", point.pos.z, 0.01, -9999, 9999, "%.3f Z")
    ImGui.PopItemWidth()
    ImGui.SameLine()
    editUI.drawPinBox("Pin", point, "pos", point.pos)
    ImGui.SameLine()
    if ImGui.Button("TP to") then
        Game.GetTeleportationFacility():Teleport(GetPlayer(), point.pos,  point.rot:ToEulerAngles())
    end

    ImGui.PushItemWidth(150)
    local x, changed = ImGui.DragFloat("##r_x", 0, 0.01, -9999, 9999, "%.3f Relativ X")
    if changed then
        if track.trainObj.spawned then
            local v = track.trainObj.entity:GetWorldRight()
            point.pos.x = point.pos.x + (v.x * x)
            point.pos.y = point.pos.y + (v.y * x)
        end
        x = 0
    end
    ImGui.SameLine()
    local y, changed = ImGui.DragFloat("##r_y", 0, 0.01, -9999, 9999, "%.3f Relativ Y")
    if changed then
        if track.trainObj.spawned then
            local v = track.trainObj.entity:GetWorldForward()
            point.pos.x = point.pos.x + (v.x * y)
            point.pos.y = point.pos.y + (v.y * y)
            point.pos.z = point.pos.z + (v.z * y)
        end
        y = 0
    end
    ImGui.PopItemWidth()
-- Rotation
    if point.euler == nil then
        point.euler = point.rot:ToEulerAngles()
    end

    ImGui.PushItemWidth(100)
    point.euler.roll, changed = ImGui.DragFloat("##roll", point.euler.roll, 0.01, -9999, 9999, "%.3f Roll")
    if changed then
        point.rot = point.euler:ToQuat()
    end
    ImGui.SameLine()
    point.euler.pitch, changed = ImGui.DragFloat("##pitch", point.euler.pitch, 0.01, -9999, 9999, "%.3f Pitch")
    if changed then
        point.rot = point.euler:ToQuat()
    end
    ImGui.SameLine()
    point.euler.yaw, changed = ImGui.DragFloat("##yaw", point.euler.yaw, 0.01, -9999, 9999, "%.3f Yaw")
    if changed then
        point.rot = point.euler:ToQuat()
    end
    ImGui.PopItemWidth()

    local state = ImGui.CollapsingHeader("(Un)load triggers")
    if state then
        ImGui.Text("Load Station / Spawn train:")
        ImGui.PushID("loadStation")
        point.loadStation.last = ImGui.Checkbox('LAST', point.loadStation.last)
        point.loadStation.next = ImGui.Checkbox('NEXT', point.loadStation.next)
        ImGui.Text("Last: Triggers if track is being used backwards (index decrease), and vice versa")
        ImGui.PopID()

        ImGui.Separator()

        ImGui.Text("Unload Station / Despawn Train")
        point.unloadStation.last = ImGui.Checkbox('LAST', point.unloadStation.last)
        point.unloadStation.next = ImGui.Checkbox('NEXT', point.unloadStation.next)
    end

    if ImGui.Button("Delete") then
        utils.removeItem(track.points, point)
        track.currentPointID = math.max(track.currentPointID - 1, 1)
    end

    ImGui.EndChild()
    CPS.colorEnd(1)
end

function editUI.drawPinBox(lable, data, name, pos)
    if data.pins == nil then -- Create field to store state and id of pins, to make disabling them per data easy
        data.pins = {}
    end
    if data.pins[name] == nil then
        data.pins[name] = false
    end
    if data.pinIDs == nil then
        data.pinIDs = {}
    end

    ImGui.PushID(name)
    data.pins[name], changed = ImGui.Checkbox(lable, data.pins[name])
    ImGui.PopID()
    if changed then
        editUI.handleWaypoint(data, pos, name)
    end
end

function editUI.handleWaypoint(data, pos, name)
    if data.pins[name] then
        local mappinData = NewObject('gamemappinsMappinData')
        mappinData.mappinType = TweakDBID.new('Mappins.DefaultStaticMappin')
        mappinData.variant = Enum.new('gamedataMappinVariant', 'FastTravelVariant')
        mappinData.visibleThroughWalls = true
        local id = Game.GetMappinSystem():RegisterMappin(mappinData, pos)
        data.pinIDs[name] = id
    else
        Game.GetMappinSystem():UnregisterMappin(data.pinIDs[name])
    end
end

function editUI.deleteAllPins(data)
    if editUI.type == "track" then
        for _, v in pairs(data.points) do
            if v.pins ~= nil then
                for _, id in pairs(v.pinIDs) do
                    Game.GetMappinSystem():UnregisterMappin(id)
                end
            end
        end
    end

    if data.pins ~= nil then
        for _, id in pairs(data.pinIDs) do
            Game.GetMappinSystem():UnregisterMappin(id)
        end
    end
end

function editUI.deleteAllObjects(data)
    -- if data.objects ~= nil then
    --     for _, obj in pairs(data.objects) do
    --         obj:despawn()
    --     end
    -- end
end

function editUI.update()
    if editUI.type == "track" then
        editUI.currentData.trainObj:update()
    end
end

return editUI