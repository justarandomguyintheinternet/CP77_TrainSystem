local settings = require("modules/utils/GameSettings")

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

function miscUtils.fromEuler(eul) -- Returns table with roll pitch yaw from given EulerAngles
    return {roll = eul.roll, pitch = eul.pitch, yaw = eul.yaw}
end

function miscUtils.getEuler(eul) -- Returns EulerAngles object from given table containing roll pitch yaw
    return(EulerAngles.new(eul.roll, eul.pitch, eul.yaw))
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

function miscUtils.mount(entID, seat)
    local player = Game.GetPlayer()

    local data = NewObject('handle:gameMountEventData')
    data.isInstant = true
    data.slotName = seat
    data.mountParentEntityId = entID
    data.entryAnimName = "forcedTransition"

    local slotID = NewObject('gamemountingMountingSlotId')
    slotID.id = seat

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
    local event = gamemountingUnmountingRequest.new()
    local info = gamemountingMountingInfo.new()
    info.childId = Game.GetPlayer():GetEntityID()
    event.lowLevelMountingInfo = info
    event.mountData = gameMountEventData.new()
    event.mountData.isInstant = true
    event.mountData.removePitchRollRotationOnDismount = true
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

    local rot = point.rot:ToEulerAngles()
    rot.roll = rot.roll * -1
    rot.pitch = rot.pitch * -1
    rot.yaw = rot.yaw + 180

    newPoint.rot = rot:ToQuat()
    return newPoint
end

function miscUtils.reversePointPitch(point)
    local p = require("modules/classes/point") -- Clone the point, dont wanna change the original points rot
    local newPoint = p:new()
    newPoint.dir = point.dir
    newPoint.unloadStation = point.unloadStation
    newPoint.loadStation = point.loadStation
    newPoint.pos = point.pos

    local rot = point.rot:ToEulerAngles()
    rot.roll = rot.roll * -1
    rot.pitch = rot.pitch * -1
    newPoint.rot = rot:ToQuat()
    return newPoint
end

function miscUtils.setRadioStation(vehicle, stationID) -- -1 means off
    if stationID ~= -1 then
        vehicle:ToggleRadioReceiver(true)
        vehicle:SetRadioReceiverStation(stationID)
    else
        vehicle:ToggleRadioReceiver(false)
    end
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

function miscUtils.isVector(v1, v2) -- Returns true if two vectors are the same
    return (v1.x == v2.x) and (v1.y == v2.y) and (v1.z == v2.z)
end

function miscUtils.calcDeltaEuler(eul1, eul2)
    local delta = EulerAngles.new(0, 0, 0)

    local deltaRoll = eul1.roll - eul2.roll
    local altDeltaRoll = (180 - math.abs(eul1.roll)) + (180 - math.abs(eul2.roll))
    if eul1.roll > eul2.roll then
        altDeltaRoll = - altDeltaRoll
    end
    if math.abs(deltaRoll) < math.abs(altDeltaRoll) then
        delta.roll = deltaRoll
    else
        delta.roll = altDeltaRoll
    end

    local deltaPitch = eul1.pitch - eul2.pitch
    local altDeltaPitch = (180 - math.abs(eul1.pitch)) + (180 - math.abs(eul2.pitch))
    if eul1.pitch > eul2.pitch then
        altDeltaPitch = - altDeltaPitch
    end
    if math.abs(deltaPitch) < math.abs(altDeltaPitch) then
        delta.pitch = deltaPitch
    else
        delta.pitch = altDeltaPitch
    end

    local deltaYaw = eul1.yaw - eul2.yaw
    local altDeltaYaw = (180 - math.abs(eul1.yaw)) + (180 - math.abs(eul2.yaw))
    if eul1.yaw > eul2.yaw then
        altDeltaYaw = - altDeltaYaw
    end
    if math.abs(deltaYaw) < math.abs(altDeltaYaw) then
        delta.yaw = deltaYaw
    else
        delta.yaw = altDeltaYaw
    end

    return delta
end

function miscUtils.spawnObject(path, pos, rot, appearance)
    local app = appearance or ""
    local transform = Game.GetPlayer():GetWorldTransform()
    transform:SetOrientation(rot)
    transform:SetPosition(pos)
    local entityID = exEntitySpawner.Spawn(path, transform, app)
    return entityID
end

-- All this code has been created by psiberx
function miscUtils.createInteractionChoice(action, title)
    local choiceData =  InteractionChoiceData.new()
    choiceData.localizedName = title
    choiceData.inputAction = action

    local choiceType = ChoiceTypeWrapper.new()
    choiceType:SetType(gameinteractionsChoiceType.Blueline)
    choiceData.type = choiceType

    return choiceData
end

function miscUtils.prepareVisualizersInfo(hub)
    local visualizersInfo = VisualizersInfo.new()
    visualizersInfo.activeVisId = hub.id
    visualizersInfo.visIds = { hub.id }

    return visualizersInfo
end

function miscUtils.createInteractionHub(titel, action, active)
    local choiceHubData =  InteractionChoiceHubData.new()
    choiceHubData.id = -1001
    choiceHubData.active = active
    choiceHubData.flags = EVisualizerDefinitionFlags.Undefined
    choiceHubData.title = titel

    local choices = {}
    table.insert(choices, miscUtils.createInteractionChoice(action, titel))
    choiceHubData.choices = choices

    local visualizersInfo = miscUtils.prepareVisualizersInfo(choiceHubData)

    local blackboardDefs = Game.GetAllBlackboardDefs()
    local interactionBB = Game.GetBlackboardSystem():Get(blackboardDefs.UIInteractions)
    interactionBB:SetVariant(blackboardDefs.UIInteractions.InteractionChoiceHub, ToVariant(choiceHubData), true)
    interactionBB:SetVariant(blackboardDefs.UIInteractions.VisualizersInfo, ToVariant(visualizersInfo), true)
end
-- ^^^^ All this code has been created by psiberx ^^^^

function miscUtils.setupTPPCam(dist)
    TweakDB:SetFlat("Camera.VehicleTPP_Brennan_Preset_High_Far.boomLength", dist)
    TweakDB:SetFlat("Camera.VehicleTPP_Default_Preset_Low_Far.boomLength", dist)
    TweakDB:SetFlat("Camera.VehicleTPP_Brennan_Preset_Low_Far.boomLength", dist)
    TweakDB:SetFlat("Camera.VehicleTPP_2w_DefaultParams.autoCenterStartTimeMouse", 150000)
    TweakDB:SetFlat("Camera.VehicleTPP_2w_DefaultParams.autoCenterStartTimeGamepad", 150000)

    TweakDB:SetFlat("Vehicle.v_mahir_mt28_coach_inline6.tireRadius", 0.08)
    TweakDB:SetFlat("Vehicle.v_mahir_mt28_coach_inline7.tireRadius", 0.08)
    TweakDB:SetFlat("Vehicle.v_mahir_mt28_coach_inline6.wheelOffset", 16)
    TweakDB:SetFlat("Vehicle.v_mahir_mt28_coach_inline7.wheelOffset", 16)
    TweakDB:SetFlat("Vehicle.v_mahir_mt28_coach_inline6.rimRadius", 0.05)
    TweakDB:SetFlat("Vehicle.v_mahir_mt28_coach_inline7.rimRadius", 0.05)
    TweakDB:SetFlat("Vehicle.v_mahir_mt28_coach_inline6.tireWidth", 0.05)
    TweakDB:SetFlat("Vehicle.v_mahir_mt28_coach_inline7.tireWidth", 0.05)

    TweakDB:SetFlat("Vehicle.v_sportbike3_brennan_apollo_inline3.tireRadius", 0.08)
    TweakDB:SetFlat("Vehicle.v_sportbike3_brennan_apollo_inline4.tireRadius", 0.08)
    TweakDB:SetFlat("Vehicle.v_sportbike3_brennan_apollo_inline3.wheelOffset", 16)
    TweakDB:SetFlat("Vehicle.v_sportbike3_brennan_apollo_inline4.wheelOffset", 16)
    TweakDB:SetFlat("Vehicle.v_sportbike3_brennan_apollo_inline3.rimRadius", 0.05)
    TweakDB:SetFlat("Vehicle.v_sportbike3_brennan_apollo_inline4.rimRadius", 0.05)
    TweakDB:SetFlat("Vehicle.v_sportbike3_brennan_apollo_inline3.tireWidth", 0.05)
    TweakDB:SetFlat("Vehicle.v_sportbike3_brennan_apollo_inline4.tireWidth", 0.05)
end

function miscUtils.removeTPPTweaks()
    TweakDB:SetFlat("Camera.VehicleTPP_Brennan_Preset_High_Far.boomLength", 4.500000)
    TweakDB:SetFlat("Camera.VehicleTPP_Default_Preset_Low_Far.boomLength", 4.500000)
    TweakDB:SetFlat("Camera.VehicleTPP_Brennan_Preset_Low_Far.boomLength", 4.500000)
    TweakDB:SetFlat("Camera.VehicleTPP_2w_DefaultParams.autoCenterStartTimeMouse", 2.000000)
    TweakDB:SetFlat("Camera.VehicleTPP_2w_DefaultParams.autoCenterStartTimeGamepad", 0.5)

    TweakDB:SetFlat("Vehicle.v_mahir_mt28_coach_inline6.tireRadius", 0.460000)
    TweakDB:SetFlat("Vehicle.v_mahir_mt28_coach_inline7.tireRadius", 0.460000)
    TweakDB:SetFlat("Vehicle.v_mahir_mt28_coach_inline6.wheelOffset", 0)
    TweakDB:SetFlat("Vehicle.v_mahir_mt28_coach_inline7.wheelOffset", -0.070000)
    TweakDB:SetFlat("Vehicle.v_mahir_mt28_coach_inline6.rimRadius", 0.24)
    TweakDB:SetFlat("Vehicle.v_mahir_mt28_coach_inline7.rimRadius", 0.24)
    TweakDB:SetFlat("Vehicle.v_mahir_mt28_coach_inline6.tireWidth", 0.33)
    TweakDB:SetFlat("Vehicle.v_mahir_mt28_coach_inline7.tireWidth", 0.47)

    TweakDB:SetFlat("Vehicle.v_sportbike3_brennan_apollo_inline3.tireRadius", 0.305000)
    TweakDB:SetFlat("Vehicle.v_sportbike3_brennan_apollo_inline4.tireRadius", 0.305000)
    TweakDB:SetFlat("Vehicle.v_sportbike3_brennan_apollo_inline3.wheelOffset", 0)
    TweakDB:SetFlat("Vehicle.v_sportbike3_brennan_apollo_inline4.wheelOffset", 0)
    TweakDB:SetFlat("Vehicle.v_sportbike3_brennan_apollo_inline3.rimRadius", 0.3)
    TweakDB:SetFlat("Vehicle.v_sportbike3_brennan_apollo_inline4.rimRadius", 0.3)
    TweakDB:SetFlat("Vehicle.v_sportbike3_brennan_apollo_inline3.tireWidth", 0.13)
    TweakDB:SetFlat("Vehicle.v_sportbike3_brennan_apollo_inline4.tireWidth", 0.15)
end

function miscUtils.showInputHint(key, text, container, prio, holdAnimation)
    local hold = holdAnimation or false
    local evt = UpdateInputHintEvent.new()
    local data = InputHintData.new()
    data.action = key
    data.source = "train"
    data.localizedLabel = text
    data.enableHoldAnimation = hold
    data.sortingPriority  = prio or 1
    evt = UpdateInputHintEvent.new()
    evt.data = data
    evt.show = true
    evt.targetHintContainer = container or "GameplayInputHelper"
    Game.GetUISystem():QueueEvent(evt)
end

function miscUtils.hideCustomHints()
    local evt = DeleteInputHintBySourceEvent.new()
    evt.source = "train"
    evt.targetHintContainer = "GameplayInputHelper"
    Game.GetUISystem():QueueEvent(evt)
end

function miscUtils.forceStop(ts)
    ts.entrySys:despawnElevators()
    ts.objectSys.despawnAll()
    miscUtils.removeTPPTweaks()
    miscUtils.toggleHUD(true)

    if ts.observers.noSave then
        ts.stationSys.currentStation:despawn()
        if ts.stationSys.previousStationID then
            ts.stationSys.stations[ts.stationSys.previousStationID]:despawn()
        end

        if ts.stationSys.activeTrain then
            ts.observers.noSave = false
            ts.observers.noKnockdown = false
            ts.observers.noFastTravel = false
            ts.observers.activatedGate = false
            pcall(function()
                ts.stationSys.activeTrain:unmount()
            end)
            ts.stationSys.activeTrain:despawn()
            StatusEffectHelper.RemoveStatusEffect(GetPlayer(), "GameplayRestriction.NoDriving")
            StatusEffectHelper.RemoveStatusEffect(GetPlayer(), "GameplayRestriction.NoCombat")
            StatusEffectHelper.RemoveStatusEffect(GetPlayer(), "GameplayRestriction.VehicleBlockExit")
            Game.ChangeZoneIndicatorPublic()
            settings.Set("/interface/hud/input_hints", ts.stationSys.inputHintsOriginal)
            settings.Set("/interface/hud/quest_tracker", ts.stationSys.jobTrackerOriginal)
            if ts.observers.hudText then ts.observers.hudText:SetVisible(false) end
            miscUtils.togglePin(ts.stationSys, "exit", false)
            Game.GetTeleportationFacility():Teleport(Game.GetPlayer(), ts.stationSys.currentStation.groundPoint.pos,  (ts.stationSys.currentStation.groundPoint.rot):ToEulerAngles())

            ts.entrySys = require("modules/entrySystem"):new(ts)
            ts.stationSys = require("modules/stationSystem"):new(ts)
            ts.trackSys = require("modules/trackSystem"):new(ts)

            ts.trackSys:load()
            ts.entrySys:load()
            ts.stationSys:load()
            ts.objectSys.initialize()
        end
    end
end

function miscUtils.playAudio(target, clipName)
    local audioEvent = SoundPlayEvent.new()
    audioEvent.soundName = clipName
    target:QueueEvent(audioEvent)
end

function miscUtils.stopAudio(target, clipName)
    local audioEvent = SoundStopEvent.new()
    audioEvent.soundName = clipName
    target:QueueEvent(audioEvent)
end

function miscUtils.toggleHUD(state)
    if not Game.GetPlayer() then return end

    if state then
        Game.GetUISystem():ResetGameContext()
    else
        Game.GetUISystem():PushGameContext(UIGameContext.ModalPopup)
    end
end

function miscUtils.fixNoFastTravel()
    if not Game.GetMountedVehicle(GetPlayer()) then
        for _, reason in pairs(Game.GetUISystem():GetFastTravelSystem().fastTravelLocks) do
            if reason.lockReason.value == "InVehicle" then
                Game.GetUISystem():GetFastTravelSystem():OnRemoveAllFastTravelLocksRequest(RemoveAllFastTravelLocksRequest.new())
            end
        end
    end
end

function miscUtils.generateHUDMargin(type)
    if type == 1 then -- Vanilla
        return inkMargin.new({ left = 355.0, top = 1960.0, right = 0.0, bottom = 0.0 })
    elseif type == 2 then -- E3
        return inkMargin.new({ left = 355.0, top = 1250.0, right = 0.0, bottom = 0.0 })
    elseif type == 3 then -- Superior
        return inkMargin.new({ left = 355.0, top = 1960.0, right = 0.0, bottom = 0.0 }) -- Its the same lol, but i`ll leave it cuz its cool
    end
end

function miscUtils.generateHUDColor(type)
    if type == 1 or type == 2 then -- Vanilla and E3
        return HDRColor.new({ Red = 1.1761, Green = 0.3809, Blue = 0.3476, Alpha = 1.0 })
    elseif type == 3 then -- Superior
        return HDRColor.new({ Red = 1, Green = 1, Blue = 1, Alpha = 0.95 })
    end
end

return miscUtils