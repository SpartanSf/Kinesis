local arg1dir = kFs.join(kFs.currentdir(), args[1])
local arg2dir = kFs.join(kFs.currentdir(), args[2])
kFs.copy(arg1dir, arg2dir)
