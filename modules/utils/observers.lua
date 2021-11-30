Cron = require("modules/utils/Cron")
utils = require("modules/utils/utils")

observers = {
    noFastTravel = false,
    activatedGate = false,
    noSave = false,
    noKnockdown = false,
    timetableValue = 0,
    trainIDS = {},
    ts = nil,
    hudText = nil,
    onMap = false,
    worldMap = nil
}

function observers.start(ts)
    observers.ts = ts

    -- ObserveAfter("DlcMenuGameController", "OnInitialize", function(this) -- Funny but stupid
    --     local data = DlcDescriptionData.new()
    --     CName.add("trainSystem")
    --     data.guide = "trainSystem"
    --     this:AsyncSpawnFromLocal(inkWidgetRef.Get(this.containersRef), "dlcDescription", this, "OnDescriptionSpawned", data)
    -- end)

    -- Override("DlcDescriptionController", "SetData", function (this, data, wrapped)
    --     if data.guide.value == "trainSystem" then
    --         inkTextRef.SetText(this.titleRef, "Train System")
    --         inkTextRef.SetText(this.descriptionRef, "This adds a fully useable NCART System, with 19 Stations and tons of tracks to explore")
    --         inkTextRef.SetText(this.guideRef, "Go to any of the \"Metro: ...\" fast travel points to use it")
    --         inkImageRef.SetTexturePart(this.imageRef, "none")
    --     else
    --         wrapped(data)
    --     end
    -- end)

    -- Override("DlcMenuGameController", "SpawnDescriptions", function (_, titel, desc, guide, image, wrapped)
    --     if guide.value == "UI-DLC-JohnnyAltApp_Guide" then -- Im sorry...
    --         return
    --     else
    --         wrapped(titel, desc, guide, image)
    --     end
    -- end)

    Override("FakeDoor", "CreateFakeDoorChoice", function(_, wrapped)
        if observers.noSave then return end
        wrapped()
    end)

    Observe("WorldMapMenuGameController", "OnInitialize", function (this)
        observers.onMap = true
        observers.worldMap = this
    end)

    Observe("WorldMapMenuGameController", "OnUninitialize", function ()
        observers.onMap = false
    end)

    Observe("WorldMapMenuGameController", "RefreshInputHints", function ()
        utils.showInputHint("UI_Apply", "Track closest NCART Station", "WorldMapInputHints", 10)
    end)

    Observe('QuestTrackerGameController', 'OnInitialize', function(self)
        local rootWidget = self:GetRootCompoundWidget()

        local label = inkText.new()
        CName.add("ncartTracker")
        label:SetName('ncartTracker')
        label:SetFontFamily('base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily')
        label:SetFontStyle('Medium')
        label:SetFontSize(40)
        label:SetLetterCase(textLetterCase.OriginalCase)
        label:SetTintColor(HDRColor.new({ Red = 1.1761, Green = 0.3809, Blue = 0.3476, Alpha = 1.0 }))
        label:SetAnchor(inkEAnchor.Fill)
        label:SetHorizontalAlignment(textHorizontalAlignment.Center)
        label:SetVerticalAlignment(textVerticalAlignment.Center)
        label:SetMargin(inkMargin.new({ left = 355.0, top = 1750.0, right = 0.0, bottom = 0.0 }))
        label:SetText("")
        label:SetVisible(false)
        label:Reparent(rootWidget, -1)

        observers.hudText = label
    end)

    Override('hudCarController', 'OnMountingEvent', function(this)
        if observers.noSave then
            this.activeVehicle = GetMountedVehicle(GetPlayer())
            this.driver = VehicleComponent.IsDriver(GetPlayer())
            this:RegisterToVehicle(true)
            this:Reset()
            this:GetRootWidget():GetWidgetByPath(BuildWidgetPath({ 'maindashcontainer'})):SetVisible(false)
            this:GetRootWidget():GetWidgetByPath(BuildWidgetPath({ 'holder_code'})):SetVisible(false)
            this:GetRootWidget():GetWidgetByPath(BuildWidgetPath({ 'flufftext'})):SetVisible(false)
            this:GetRootWidget():GetWidgetByPath(BuildWidgetPath({ 'speed_fluff'})):SetVisible(false)
        else
            this.activeVehicle = GetMountedVehicle(GetPlayer())
            this.driver = VehicleComponent.IsDriver(GetPlayer())
            this:GetRootWidget():SetVisible(false)
            this:RegisterToVehicle(true)
            this:Reset()
        end
        collectgarbage()
    end)

    Override("gameScriptableSystem", "IsSavingLocked", function(_, wrapped)
        if observers.noSave then
            return true
        else
            return wrapped()
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