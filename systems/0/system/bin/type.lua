local path = kFs.join(kFs.currentdir(), args[1])
if kFs.exists(path) then
    term.write(kFs.isDir(kFs.currentdir() .. "/" .. (args[1] or "")) and "dir" or "file")
else term.write("Path does not exist") end
