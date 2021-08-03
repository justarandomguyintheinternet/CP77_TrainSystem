baseUI = {
    CPS = require("CPStyling"),
    createUI = require("debug/ui/tabs/createUI"),
    loadedUI = require("debug/ui/tabs/loadedUI"),
    fileUI = require("debug/ui/tabs/fileUI"),
    editUI = require("debug/ui/tabs/editUI"),
    rmUI = require("debug/ui/tabs/removalUI"),
    utilUI = require("debug/ui/tabs/utilUI"),
    switchToEdit = false,
    switchToLoaded = false
}

function baseUI.getSwitchFlag(tab)
    if tab == "edit" and baseUI.switchToEdit then
        baseUI.switchToEdit = false
        return ImGuiTabItemFlags.SetSelected
    elseif tab == "loaded" and baseUI.switchToLoaded then
        baseUI.switchToLoaded = false
        return ImGuiTabItemFlags.SetSelected
    else
        return ImGuiTabItemFlags.None
    end
end

function baseUI.draw(debug)
    baseUI.CPS:setThemeBegin()
    ImGui.Begin("trainSystem Debug Tool", ImGuiWindowFlags.AlwaysAutoResize)

    if ImGui.BeginTabBar("Tabbar", ImGuiTabBarFlags.NoTooltip) then
        baseUI.CPS.styleBegin("TabRounding", 0)

        if ImGui.BeginTabItem("Create Data") then
            baseUI.createUI.draw(debug)
            ImGui.EndTabItem()
        end

        if ImGui.BeginTabItem("Loaded Data", baseUI.getSwitchFlag("loaded")) then
            baseUI.loadedUI.draw(debug)
            ImGui.EndTabItem()
        end

        if ImGui.BeginTabItem("Edit", baseUI.getSwitchFlag("edit")) then
            baseUI.editUI.draw(debug)
            ImGui.EndTabItem()
        end

        if ImGui.BeginTabItem("Files") then
            baseUI.fileUI.draw(debug)
            ImGui.EndTabItem()
        end

        if ImGui.BeginTabItem("Removal") then
            baseUI.rmUI.draw()
            ImGui.EndTabItem()
        end

        if ImGui.BeginTabItem("Utils") then
            baseUI.utilUI.draw()
            ImGui.EndTabItem()
        end

        baseUI.CPS.styleEnd(1)
        ImGui.EndTabBar()
    end

    ImGui.End()
    baseUI.CPS:setThemeEnd()
end

return baseUI