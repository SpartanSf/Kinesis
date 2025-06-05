local path = kFs.join(kFs.currentdir(), args[1])
if kFs.exists(path) then kFs.chdir(kFs.currentdir() .. "/" .. args[1]) else term.write("Invalid path") end
