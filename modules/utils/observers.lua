Cron = require("modules/utils/Cron")
utils = require("modules/utils/utils")

observers = {
    noFastTravel = false,
    activatedGate = false,
    noSave = false,
    noKnockdown = false,
    timetableValue = 0,
    trainIDS = {},
    ts = nil
}


function observers.start(ts)
    observers.ts = ts

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

    Observe("VehicleRadioPopupGameController", "Activate", function(this)
        local data = this.selectedItem:GetStationData()
        local i = data.record:Index()
        if ts.stationSys.activeTrain.perspective == "tpp" then
            utils.setRadioStation(ts.stationSys.activeTrain.busObject.entity, i)
        else
            utils.setRadioStation(ts.stationSys.activeTrain.carObject.entity, i)
        end
        ts.stationSys.activeTrain.radioStation = i
    end)

    Override("CollisionExitingEvents", "OnEnter", function (this, stateContext, scriptInterface)
        if not observers.noKnockdown then
            local collisionDirection = Vector4.new(0.00, 0.00, 0.00, 0.00)
            local stackcount = 1

            ImmediateExitWithForceEvents.OnEnter(this, stateContext, scriptInterface)
            local impulse = stateContext:GetTemporaryVectorParameter("ExitForce")
            if impulse.valid then
                collisionDirection = -impulse.value
            end

            local statusEffectRecord = TweakDBInterface.GetStatusEffectRecord("BaseStatusEffect.BikeKnockdown")
            Game.GetStatusEffectSystem():ApplyStatusEffect(scriptInterface.executionOwner:GetEntityID(), statusEffectRecord:GetID(), scriptInterface.owner:GetTDBID(), scriptInterface.owner:GetEntityID(), stackcount, collisionDirection)
            this.animFeatureStatusEffect = AnimFeature_StatusEffect.new()
            StatusEffectHelper.PopulateStatusEffectAnimData(scriptInterface.executionOwner, statusEffectRecord, EKnockdownStates.Start, collisionDirection)
            scriptInterface:SetAnimationParameterFeature("StatusEffect", this.animFeatureStatusEffect, scriptInterface.executionOwner)
            stateContext:SetPermanentFloatParameter(StatusEffectHelper.GetStateStartTimeKey(), EngineTime.ToFloat(Game.GetPlayer()), true)
            stateContext:SetPermanentScriptableParameter(StatusEffectHelper.GetForceKnockdownKey(), statusEffectRecord, true)
            if this.exitForce.valid then
                stateContext:SetPermanentVectorParameter(StatusEffectHelper.GetForcedKnockdownImpulseKey(), this.exitForce.value, true)
            end
            this:PlaySound("v_mbike_dst_crash_fall", scriptInterface)
        end
    end)

    Override("DataTerm", "OnOpenWorldMapAction", function(this)
        if observers.noFastTravel then
            observers.activatedGate = true
        else
            this:EnableFastTravelOnMap()
            this:TriggerMenuEvent("OnOpenFastTravel")
            this:ProcessFastTravelTutorial()
        end
    end)

    Override("NcartTimetableControllerPS", "GetCurrentTimeToDepart", function(this)
        if observers.noSave then
            return math.floor(math.max(observers.timetableValue, 0))
        else
            return this.currentTimeToDepart
        end
    end)

    -- All credits for the following two Overrides go to psiberx from the CP2077 Modding Community Server
    Override('WarningMessageGameController', 'UpdateWidgets', function(self)
        if self.simpleMessage.isShown and self.simpleMessage.message ~= '' then
            self.root:StopAllAnimations()

            inkTextRef.SetLetterCase(self.mainTextWidget, textLetterCase.UpperCase)
            inkTextRef.SetText(self.mainTextWidget, self.simpleMessage.message)

            Game.GetAudioSystem():Play('ui_jingle_chip_malfunction')

            self.animProxyShow = self:PlayLibraryAnimation('warning')

            local fakeAnim = inkAnimTransparency.new()
            fakeAnim:SetStartTransparency(1.00)
            fakeAnim:SetEndTransparency(1.00)
            fakeAnim:SetDuration(3.2)

            local fakeAnimDef = inkAnimDef.new()
            fakeAnimDef:AddInterpolator(fakeAnim)

            self.animProxyTimeout = self.root:PlayAnimation(fakeAnimDef)
            self.animProxyTimeout:RegisterToCallback(inkanimEventType.OnFinish, self, 'OnShown')

            self.root:SetVisible(true)
        elseif self.animProxyShow then
            self.animProxyShow:RegisterToCallback(inkanimEventType.OnFinish, self, 'OnHidden')
            self.animProxyShow:Resume()
        end
    end)

    Override('WarningMessageGameController', 'OnShown', function(self)
        self.animProxyShow:Pause()
        self:SetTimeout(self.simpleMessage.duration)
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