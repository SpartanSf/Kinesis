local filename = kFs.join(kFs.currentdir(), args[1])
local n = tonumber(args[2]) or 10

local file = kFs.open(filename, "r")

local buffer = {}
for line in file:lines() do
    table.insert(buffer, line)
    if #buffer > n then table.remove(buffer, 1) end
end

for _, line in ipairs(buffer) do
    term.write(line.."\n")
end

file:close()
