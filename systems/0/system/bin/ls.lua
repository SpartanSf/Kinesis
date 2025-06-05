local path = kFs.currentdir() .. "/" .. (args[1] or "")

if kFs.exists(path) then
  local files = kFs.list(path)

  local maxlen = 0

  for _,file in ipairs(files) do
    if #file > maxlen then maxlen = #file end
  end

  maxlen = maxlen + 2

  for _,file in ipairs(files) do -- one hell of a one-liner
    term.write(file .. string.rep(" ", maxlen - #file) .. (kFs.isDir(path .. "/" .. file) and "DIR" or "FILE") .. "\n")
  end
else term.write("Invalid path") end
