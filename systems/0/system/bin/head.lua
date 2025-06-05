local filename = kFs.join(kFs.currentdir(), args[1])
local n = tonumber(args[2]) or 10

local file = kFs.open(filename, "r")

local count = 0
for line in file:lines() do
    term.write(line.."\n")
    count = count + 1
    if count >= n then break end
end

file:close()
