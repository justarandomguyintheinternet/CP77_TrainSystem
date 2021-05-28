miscUtils = {}

function miscUtils.deepcopy(origin)
	local orig_type = type(origin)
    local copy
    if orig_type == 'table' then
        copy = {}
        for origin_key, origin_value in next, origin, nil do
            copy[miscUtils.deepcopy(origin_key)] = miscUtils.deepcopy(origin_value)
        end
        setmetatable(copy, miscUtils.deepcopy(getmetatable(origin)))
    else
        copy = origin
    end
    return copy
end

function miscUtils.distanceVector(from, to)
    return math.sqrt((to.x - from.x)^2 + (to.y - from.y)^2 + (to.z - from.z)^2)
end

function miscUtils.fromVector(vector) -- Returns table with x y z w from given Vector4
    return {x = vector.x, y = vector.y, z = vector.z, w = vector.w}
end

function miscUtils.fromQuaternion(quat) -- Returns table with i j k r from given Quaternion
    return {i = quat.i, j = quat.j, k = quat.k, r = quat.r}
end

function miscUtils.getVector(tab) -- Returns Vector4 object from given table containing x y z w
    return(Vector4.new(tab.x, tab.y, tab.z, tab.w))
end

function miscUtils.getQuaternion(tab) -- Returns Quaternion object from given table containing i j k r
    return(Quaternion.new(tab.i, tab.j, tab.k, tab.r))
end

function miscUtils.indexValue(table, value)
    local index={}
    for k,v in pairs(table) do
        index[v]=k
    end
    return index[value]
end

function miscUtils.has_value(tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

function miscUtils.getIndex(tab, val)
    local index = nil
    for i, v in ipairs(tab) do
		if v == val then
			index = i
		end
    end
    return index
end

function miscUtils.removeItem(tab, val)
    table.remove(tab, miscUtils.getIndex(tab, val))
end

function miscUtils.looksAtDoor(dist)
    local looksAt = false
    local target = Game.GetTargetingSystem():GetLookAtObject(Game.GetPlayer(), false, false)
    if target then
        if target:GetClassName().value == "FakeDoor" then
            if miscUtils.distanceVector(target:GetWorldPosition(), Game.GetPlayer():GetWorldPosition()) < dist then
                looksAt = true
            end
        end
    end
    return looksAt
end

function miscUtils.togglePin(data, name, state, pos, variant)
    local variant = variant or 'FastTravelVariant'
    if data.pins == nil then -- Create field to store state and id of pins, to make disabling them per data easy
        data.pins = {}
    end
    if data.pins[name] == nil then
        data.pins[name] = false
    end
    if data.pinIDs == nil then
        data.pinIDs = {}
    end

    data.pins[name] = state

    if data.pins[name] then
        local mappinData = NewObject('gamemappinsMappinData')
        mappinData.mappinType = TweakDBID.new('Mappins.DefaultStaticMappin')
        mappinData.variant = Enum.new('gamedataMappinVariant', variant)
        mappinData.visibleThroughWalls = true
        local id = Game.GetMappinSystem():RegisterMappin(mappinData, pos)
        data.pinIDs[name] = id
        data.pins[name] = false
    else
        Game.GetMappinSystem():UnregisterMappin(data.pinIDs[name])
        data.pins[name] = true
    end
end

function miscUtils.mount(entID)
    local player = Game.GetPlayer()

    local data = NewObject('handle:gameMountEventData')
    data.isInstant = true
    data.slotName = "seat_front_left"
    data.mountParentEntityId = entID
    data.entryAnimName = "forcedTransition"

    local slotID = NewObject('gamemountingMountingSlotId')
    slotID.id = "seat_front_left"

    local mountingInfo = NewObject('gamemountingMountingInfo')
    mountingInfo.childId = player:GetEntityID()
    mountingInfo.parentId = entID
    mountingInfo.slotId = slotID

    local mountEvent = NewObject('handle:gamemountingMountingRequest')
    mountEvent.lowLevelMountingInfo = mountingInfo
    mountEvent.mountData = data

    Game.GetMountingFacility():Mount(mountEvent)
end

function miscUtils.unmount()
    local event = NewObject("handle:gamemountingUnmountingRequest")
    local info = NewObject('gamemountingMountingInfo')
    info.childId = Game.GetPlayer():GetEntityID()
    event.lowLevelMountingInfo = info
    event.mountData = NewObject('handle:gameMountEventData')
    event.mountData.isInstant = true
    Game.GetMountingFacility():Unmount(event)
end

function miscUtils.switchCarCam(perspectiveEnum)
    local event = NewObject("handle:vehicleRequestCameraPerspectiveEvent")
    event.cameraPerspective = Enum.new("vehicleCameraPerspective", perspectiveEnum)
    Game.GetPlayer():QueueEvent(event)
end

function miscUtils.reversePoint(point)
    local p = require("modules/classes/point") -- Clone the point, dont wanna change the original points rot
    local newPoint = p:new()
    newPoint.dir = point.dir
    newPoint.unloadStation = point.unloadStation
    newPoint.loadStation = point.loadStation
    newPoint.pos = point.pos

    local rot = GetSingleton('Quaternion'):ToEulerAngles(point.rot)
    rot.roll = rot.roll * -1
    rot.pitch = rot.pitch * -1
    rot.yaw = rot.yaw + 180
    newPoint.rot = GetSingleton('EulerAngles'):ToQuat(rot)
    return newPoint
end

function miscUtils.reversePointPitch(point)
    local p = require("modules/classes/point") -- Clone the point, dont wanna change the original points rot
    local newPoint = p:new()
    newPoint.dir = point.dir
    newPoint.unloadStation = point.unloadStation
    newPoint.loadStation = point.loadStation
    newPoint.pos = point.pos

    local rot = GetSingleton('Quaternion'):ToEulerAngles(point.rot)
    rot.roll = rot.roll * -1
    rot.pitch = rot.pitch * -1
    newPoint.rot = GetSingleton('EulerAngles'):ToQuat(rot)
    return newPoint
end

function miscUtils.addVector(v1, v2)
    return Vector4.new(v1.x + v2.x, v1.y + v2.y, v1.z + v2.z, v1.w + v2.w)
end

function miscUtils.subVector(v1, v2)
    return Vector4.new(v1.x - v2.x, v1.y - v2.y, v1.z - v2.z, v1.w - v2.w)
end

function miscUtils.multVector(v1, factor)
    return Vector4.new(v1.x * factor, v1.y * factor, v1.z * factor, v1.w * factor)
end

function miscUtils.addEuler(e1, e2)
    return EulerAngles.new(e1.roll + e2.roll, e1.pitch + e2.pitch, e1.yaw + e2.yaw)
end

function miscUtils.subEuler(e1, e2)
    return EulerAngles.new(e1.roll - e2.roll, e1.pitch - e2.pitch, e1.yaw - e2.yaw)
end

function miscUtils.multEuler(e1, factor)
    return EulerAngles.new(e1.roll * factor, e1.pitch * factor, e1.yaw * factor)
end

return miscUtils