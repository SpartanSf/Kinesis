term.write("Welcome to KinesisOS!\n\n")

function sys.runString(str, env)
  local chunk, err = loadstring(str)
  if not chunk then error(err) end
  setfenv(chunk, env or getfenv(2))
  return chunk()
end

function sys.runFile(path, env)
  local file = kFs.open(path, "r")
  local code = file:read("*a")
  file:close()

  local chunk, err = loadstring(code)
  if not chunk then error(err) end
  setfenv(chunk, env or getfenv(2))
  return chunk()
end

for _,file in ipairs(kFs.list("lib")) do
  if not kFs.isDir(file) then
    sys.runFile("lib/"..file)
  end
end

sys.runFile("bin/shell.lua")
