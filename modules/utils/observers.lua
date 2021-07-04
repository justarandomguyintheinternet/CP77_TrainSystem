Cron = require("modules/utils/Cron")

observers = {
    noFastTravel = false,
    activatedGate = false,
    noSave = false,
}


function observers.start()
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
            return "SellectDestination" -- Ah yes seLLect
        end
    end)
end

return observers