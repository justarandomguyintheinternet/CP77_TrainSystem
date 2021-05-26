ui = {}

function  ui.drawEntry()
    wWidth, wHeight = GetDisplayResolution()
    ImGui.Begin("Entry", ImGuiWindowFlags.NoResize and ImGuiWindowFlags.AlwaysAutoResize and ImGuiWindowFlags.NoTitleBar) 
    ImGui.SetWindowPos(wWidth/2 - 100, wHeight/2 + 250)
    ImGui.Text("Interact to get to pad")
    ImGui.End()
end

return ui