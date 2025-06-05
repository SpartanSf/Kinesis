local file = kFs.open(kFs.currentdir() .. "/" .. (args[1] or ""), "r")
if file then term.write(file:read("*a")); file:close() else term.write("Invalid path") end
