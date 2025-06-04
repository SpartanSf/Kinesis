local file = kFs.open(kFs.currentdir() .. "/" .. args[1], "w")
table.remove(args, 1)

local fileData = table.concat(args, " ")
file:write(fileData)
file:close()
