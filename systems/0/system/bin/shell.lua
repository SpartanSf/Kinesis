local function runFileShell(path, env, args)
  if not kFs.exists(path) then return end
  local file = kFs.open(path, "r")
  local code = file:read("*a")
  file:close()

  local chunk, err = loadstring(code)
  if not chunk then error(err) end
  local fullEnv = env or getfenv(2)
  fullEnv.args = args
  setfenv(chunk, fullEnv)
  return chunk()
end

local configFile = kFs.open("config/config.sys", "r")
local configData = configFile:read("*a")
configFile:close()
configData = json.decode(configData)

local function prompt()
  term.write("\n"..kFs.currentdir()..">")
  local input = term.input(nil, true)

  local args = {}
  for arg in input:gmatch("%S+") do table.insert(args, arg) end

  if kFs.exists(args[1]) then
    local path = table.remove(args, 1)
    runFileShell(path, nil, args)
  elseif kFs.exists(args[1]..".lua") then
    local path = table.remove(args, 1)
    runFileShell(path..".lua", nil, args)
  else
    local pathFile = table.remove(args, 1)
    local found = false
    for _,path in ipairs(configData.path) do
      local files = kFs.list(path)
      for _,file in ipairs(files) do
        if file == pathFile then
          found = true
          runFileShell(path .. "/" .. file, nil, args)
          return
        elseif file == pathFile..".lua" then
          found = true
          runFileShell(path .. "/" .. file, nil, args)
          return
        end
      end
    end
    
    if not found then print("No such file") end
  end
end

while true do
  prompt()
end
