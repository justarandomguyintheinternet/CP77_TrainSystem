config = {}

function config.fileExists(filename)
    local f=io.open(filename,"r")
    if (f~=nil) then io.close(f) return true else return false end
end

function config.tryCreateConfig(path, data)
	if not config.fileExists(path) then
        local file = io.open(path, "w")
        local jconfig = json.encode(data)
        file:write(jconfig)
        file:close()
    else
        local success = pcall(function ()
            config.loadFile(path)
        end)

        if not success then
            os.remove(path)
            local file = io.open(path, "w")
            local jconfig = json.encode(data)
            file:write(jconfig)
            file:close()

            print("[Config] Error while trying to parse \"" .. path .. "\", reverted settings to default")
        end
    end
end

function config.loadFile(path)
    local file = io.open(path, "r")
    local config = json.decode(file:read("*a"))
    file:close()
    return config
end

function config.saveFile(path, data)
    local file = io.open(path, "w")
    local jconfig = json.encode(data)
    file:write(jconfig)
    file:close()
end

function config.backwardComp(path, data)
    local f = config.loadFile(path)

    for k, e in pairs(data) do
        if f[k] == nil then
            f[k] = e
        end
    end

    config.saveFile(path, f)
end

return config