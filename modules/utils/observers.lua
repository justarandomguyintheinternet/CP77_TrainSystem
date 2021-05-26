observers = {
    noFastTravel = false,
    noSave = false,
    Cron = require("modules/utils/Cron")
}


function observers.start()
    Observe("MenuScenario_HubMenu", "GetMenusState", function(self)
        if self:IsA("MenuScenario_FastTravel") then
            if observers.noFastTravel then
                observers.Cron.After(0.25, function ()
                    self:GotoIdleState()
                end)
            end
        end
    end)

    Override("gameScriptableSystem", "IsSavingLocked", function()
        return observers.noSave
    end)

    Override("OpenWorldMapDeviceAction", "GetTweakDBChoiceRecord", function()
        if observers.noFastTravel then
            return "Enter"
        else
            return "SellectDestination" -- Ah yes seLLect
        end
    end)
end

return observers