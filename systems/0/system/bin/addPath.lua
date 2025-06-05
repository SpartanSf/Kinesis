local configFile = kFs.open("config/config.sys", "r")
local configData = configFile:read("*a")
configFile:close()
configData = json.decode(configData)

if args[1] then
	table.insert(configData.path, args[1])
	local configFile = kFs.open("config/config.sys", "w")
	configFile:write(json.encode(configData))
	configFile:close()
else
	term.write("Must provide a directory to add to path")
end
