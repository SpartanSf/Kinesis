local arg1dir = kFs.join(kFs.currentdir(), args[1])
local dir,_ = kFs.splitpath(arg1dir)
term.write(dir)
