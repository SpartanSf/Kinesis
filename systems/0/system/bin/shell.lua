local function runFileShell(path, env, args)
  if not kFs.exists(path) then
    return false, "File does not exist"
  end

  local file = kFs.open(path, "r")
  local code = file:read("*a")
  file:close()

  if code:match("^%s*$") then
    return false, "Script is empty"
  end

  local chunk, err = loadstring(code, "@" .. path)
  if not chunk then
    return false, "Syntax error: " .. err
  end

  local fullEnv = env or getfenv(2)
  fullEnv.args = args
  setmetatable(fullEnv, { __index = _G })
  setfenv(chunk, fullEnv)

  local ok, result = pcall(chunk)
  if not ok then
    return false, "Runtime error: " .. result
  end

  return true, result
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

  if kFs.exists(kFs.currentdir() .. "/" .. args[1]) then
    local path = table.remove(args, 1)
    local ok, res = runFileShell(kFs.join(kFs.currentdir(), path), nil, args)
    if not ok then term.write(res) end
  elseif kFs.exists(kFs.currentdir() .. "/" .. args[1]..".lua") then
    local path = table.remove(args, 1)
    local ok, res = runFileShell(kFs.join(kFs.currentdir(), path)..".lua", nil, args)
    if not ok then term.write(res) end
  else
    local pathFile = table.remove(args, 1)
    local found = false
    for _,path in ipairs(configData.path) do
      local files = kFs.list(path)
      for _,file in ipairs(files) do
        if file == pathFile then
          found = true
          local ok, res = runFileShell(path .. "/" .. file, nil, args)
          if not ok then term.write(res) end
          return
        elseif file == pathFile..".lua" then
          found = true
          local ok, res = runFileShell(path .. "/" .. file, nil, args)
          if not ok then term.write(res) end
          return
        end
      end
    end
    
    if not found then term.write("No such file") end
  end
end

while true do
  prompt()
end
