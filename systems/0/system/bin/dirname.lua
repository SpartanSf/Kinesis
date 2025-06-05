local arg1dir = kFs.join(kFs.currentdir(), args[1])
if kFs.exists(arg1dir) then
    local dir,_ = kFs.splitpath(arg1dir)
    term.write(dir)
else term.write("Invalid path") end
