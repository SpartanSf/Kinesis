term.write(kFs.isDir(kFs.currentdir() .. "/" .. (args[1] or "")) and "dir" or "file")
