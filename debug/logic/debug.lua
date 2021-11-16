debug = {
    baseUI = require("debug/ui/baseUI")
}

function debug.run(ts)
    if ts.runtimeData.cetOpen then
        debug.baseUI.draw(debug)
    end
    debug.baseUI.loadedUI.update()
    debug.baseUI.editUI.update()
    debug.baseUI.utilUI.update()
end

return debug