local arg1dir = kFs.join(kFs.currentdir(), args[1])
local arg2dir = kFs.join(kFs.currentdir(), args[2])
if kFs.exists(arg1dir) then kFs.copy(arg1dir, arg2dir) else term.write("Invalid source") end
