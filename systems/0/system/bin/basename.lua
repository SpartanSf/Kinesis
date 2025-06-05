local arg1dir = kFs.join(kFs.currentdir(), args[1])
local _,file = kFs.splitpath(arg1dir)
term.write(file)
