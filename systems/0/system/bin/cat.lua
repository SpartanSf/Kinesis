local file = kFs.open(kFs.currentdir() .. "/" .. (args[1] or ""), "r")
term.write(file:read("*a"))
file:close()
