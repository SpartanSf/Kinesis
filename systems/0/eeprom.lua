local term = {}
local sys = {}

function term.write(text)
    for i = 1, #text do
      ioControl.put(0, string.byte(text:sub(i,i)))
    end
end

local function basicInput()
  local pressed
  local function callback(data)
    if data >= 48 and data <= 57 then
      pressed = data
      ioControl.put(0, data)
    end
  end
  ioControl.listen(1, callback)
  while not pressed do coroutine.yield() end
  ioControl.unListen(1, callback)
  return pressed - 48
end

function sys.stall()
  while true do coroutine.yield() end
end

term.write("kBoot build 000\n\n")

local bootList = {}

if kFs.isDir("boot") and kFs.exists("boot/boot.lua") then
  local bootdata = kFs.open("boot/bootdata.json")
  local data = bootdata:read("*a")
  bootdata:close()
  table.insert(bootList, {"boot/boot.lua", json.decode(data)})
end

for _,data in ipairs(kFs.list(".")) do
  if not kFs.isDir(data) then
    if data == "init.lua" then
      local bootdata = kFs.open("initdata.json")
      local data = bootdata:read("*a")
      bootdata:close()
      table.insert(bootList, {"init.lua", json.decode(data)})
    end
  end
end

for i,bootable in ipairs(bootList) do
  term.write(tostring(i).."): "..bootable[2].name.." "..bootable[2].ver.."\n")
end

term.write(">")
local choice = basicInput()

term.write("\n\nBooting "..bootList[choice][2].name.."...\n\n")

local file = kFs.open(bootList[choice][1], "r")
local code = file:read("*a")
file:close()

local chunk, err = loadstring(code)
if not chunk then error(err) end

local env = { term = term, sys = sys }
setmetatable(env, { __index = _G })

setfenv(chunk, env)
chunk()
