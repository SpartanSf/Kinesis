local files = kFs.list(kFs.currentdir() .. "/" .. (args[1] or ""))

local maxlen = 0

for _,file in ipairs(files) do
  if #file > maxlen then maxlen = #file end
end

maxlen = maxlen + 2

for _,file in ipairs(files) do -- one hell of a one-liner
  term.write(file .. string.rep(" ", maxlen - #file) .. (kFs.isDir(kFs.currentdir() .. "/" .. (args[1] or "") .. "/" .. file) and "DIR" or "FILE") .. "\n")
end
