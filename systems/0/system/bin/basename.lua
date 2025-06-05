local arg1dir = kFs.join(kFs.currentdir(), args[1])
if kFs.exists(arg1dir) then
    local _,file = kFs.splitpath(arg1dir)
    term.write(file)
else term.write("Invalid path") end
