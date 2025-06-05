local configFile = kFs.open("config/config.sys", "r")
local configData = configFile:read("*a")
configFile:close()
configData = json.decode(configData)

if kFs.exists(kFs.join(kFs.currentdir(), args[1])) then
    term.write(kFs.join(kFs.currentdir(), args[1]))
    return
elseif kFs.exists(kFs.join(kFs.currentdir(), args[1])..".lua") then
    term.write(kFs.join(kFs.currentdir(), args[1])..".lua")
    return
else
    local pathFile = table.remove(args, 1)
    local found = false
    for _,path in ipairs(configData.path) do
        local files = kFs.list(path)
        for _,file in ipairs(files) do
            if file == pathFile then
                found = true
                term.write(kFs.join(path, file))
                return
            elseif file == pathFile..".lua" then
                found = true
                term.write(kFs.join(path, file))
                return
            end
        end
    end

    if not found then term.write("No such file") end
end
