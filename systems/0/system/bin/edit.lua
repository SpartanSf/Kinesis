local function readFile(path)
    local file = kFs.open(kFs.join(kFs.currentdir(), path), "r")
    if not file then return {} end
    local lines = {}
    for line in file:lines() do
        table.insert(lines, line)
    end
    file:close()
    return lines
end

local function writeFile(path, lines)
    local file = kFs.open(kFs.join(kFs.currentdir(), path), "w")
    for _, line in ipairs(lines) do
        file:write(line .. "\n")
    end
    file:close()
end

local function edit(path)
    local lines = readFile(path)

    term.write("Loaded " .. tostring(#lines) .. " lines. Type :help for commands.\n")

    while true do
        term.write("> ")
        local input = term.input(nil, true)
        local tokens = {}
        for arg in input:gmatch("%S+") do table.insert(tokens, arg) end

        if tokens[1] == ":q" then
            break
        elseif tokens[1] == ":w" then
            writeFile(path, lines)
            term.write("Saved.\n")
        elseif tokens[1] == ":p" then
            for i, line in ipairs(lines) do
                if i > tonumber(tokens[2]) and i < tonumber(tokens[3]) then
                    term.write(i .. ": " .. line .. "\n")
                end
            end
        elseif tokens[1] == ":d" then
            local n = tonumber(tokens[2])
            if n and lines[n] then
                table.remove(lines, n)
                term.write("Deleted line " .. n .. ".\n")
            else
                term.write("Invalid line.\n")
            end
        elseif tokens[1] == ":i" then
            local n = tonumber(tokens[2])
            if n and n >= 1 and n <= #lines + 1 then
                term.write("Line to insert: ")
                local line = term.input(nil, true)
                table.insert(lines, n, line)
            else
                term.write("Invalid line number.\n")
            end
        elseif input == ":help" then
            term.write([[
Commands:
  :q          Quit
  :w          Save
  :p <s> <e>  Print buffer from <s> to <e>
  :d <n>      Delete line <n>
  :i <n>      Insert line before <n>
]])
        else
            table.insert(lines, input)
        end
    end
end

if not args[1] then
    term.write("Usage: edit <filename>\n")
else
    edit(args[1])
end
