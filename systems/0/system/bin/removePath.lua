local configFile = kFs.open("config/config.sys", "r")
local configData = configFile:read("*a")
configFile:close()
configData = json.decode(configData)

local set = {}; for _, v in ipairs(configData.path) do set[v] = true end

if args[1] and set[args[1]] then
    for i, v in ipairs(configData.path) do if v == args[1] then table.remove(configData.path, i) break end end
    local configFile = kFs.open("config/config.sys", "w")
    configFile:write(json.encode(configData))
    configFile:close()
else
    term.write("Must provide a valid directory to remove from path")
end
