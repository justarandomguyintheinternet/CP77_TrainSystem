Cron = require("modules/utils/Cron")
utils = require("modules/utils/utils")

observers = {
    noFastTravel = false,
    activatedGate = false,
    noSave = false,
    trainIDS = {},
    ts = nil
}


function observers.start(ts)
    observers.ts = ts

    Observe("MenuScenario_HubMenu", "GetMenusState", function(self)
        if self:IsA("MenuScenario_FastTravel") then
            if observers.noFastTravel then
                observers.activatedGate = true
                Cron.After(0.5, function ()
                    print("toidele")
                    self:GotoIdleState()
                end)
            end
        end
    end)

    Override("gameScriptableSystem", "IsSavingLocked", function(_)
        return observers.noSave
    end)

    Override("OpenWorldMapDeviceAction", "GetTweakDBChoiceRecord", function(_)
        if observers.noFastTravel then
            return "Enter"
        else
            return "SellectDestination" -- Ah yes se LL ect
        end
    end)

    Observe("VehicleComponent", "OnGameAttach", function(self)
        if observers.ts.runtimeData.noTrains then
            if "vehicleAVBaseObject" == self:GetVehicle():GetClassName().value then
                if ts.stationSys.backUpTrain ~= nil and self:GetVehicle():GetEntityID().hash ~= ts.stationSys.backUpTrain.entID.hash then
                    if (ts.stationSys.activeTrain ~= nil and self:GetVehicle():GetEntityID().hash ~= ts.stationSys.activeTrain.trainObject.entID.hash) or ts.stationSys.activeTrain.trainObject.spawned == false then
                        table.insert(observers.trainIDS, self:GetVehicle():GetEntityID())
                    end
                end
                if ts.stationSys.activeTrain ~= nil and self:GetVehicle():GetEntityID().hash ~= ts.stationSys.activeTrain.trainObject.entID.hash then
                    if (ts.stationSys.backUpTrain ~= nil and self:GetVehicle():GetEntityID().hash ~= ts.stationSys.backUpTrain.entID.hash) or ts.stationSys.backUpTrain == nil then
                        table.insert(observers.trainIDS, self:GetVehicle():GetEntityID())
                    end
                end
                if ts.stationSys.activeTrain == nil and ts.stationSys.backUpTrain == nil then
                    table.insert(observers.trainIDS, self:GetVehicle():GetEntityID())
                end
            end
        end
    end)
end

function observers.update()
    if observers.ts.runtimeData.noTrains then
        for _, id in pairs(observers.trainIDS) do
            local ent = Game.FindEntityByID(id)
            if ent ~= nil then
                ent:Dispose()
            else
                utils.removeItem(observers.trainIDS, id)
            end
        end
    end
end

return observers