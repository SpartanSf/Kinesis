local history = {}

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

local function savePrompt()
    local doSave
    repeat
        term.write("Your progress in unsaved. Continue? [Y/n]: ")
        local usrIn = string.lower(term.input(nil, true))
        if usrIn == "y" or usrIn == "n" then doSave = usrIn end
    until doSave
    return doSave == "y" and true or false
end

local function edit(path)
    local saved = false
    local lines = readFile(path)

    term.write("Loaded " .. tostring(#lines) .. " lines. Type :help for commands.\n")

    while true do
        term.write("> ")
        local input = term.input(nil, true)
        local tokens = {}
        for arg in input:gmatch("%S+") do table.insert(tokens, arg) end

        if tokens[1] == ":q" then
            local doQuit = true
            if not saved then doQuit = savePrompt() end
            if doQuit then break end
        elseif tokens[1] == ":w" then
            writeFile(path, lines)
            term.write("Saved.\n")
            saved = true
        elseif tokens[1] == ":p" then
            local s, e = tonumber(tokens[2]), tonumber(tokens[3])
            if not s or not e then
                term.write("Invalid line range.\n")
                goto endp
            end
            for i, line in ipairs(lines) do
                if i >= s and i <= e then
                    term.write(i .. ": " .. line .. "\n")
                end
            end
            ::endp::
        elseif tokens[1] == ":d" then
            local n = tonumber(tokens[2])
            if n and lines[n] then
                local deleted = lines[n]
                table.remove(lines, n)
                table.insert(history, {":d", deleted, n})
                term.write("Deleted line " .. n .. ".\n")
                saved = false
            else
                term.write("Invalid line.\n")
            end
        elseif tokens[1] == ":i" then
            local n = tonumber(tokens[2])
            local start = n
            if n and n >= 1 and n <= #lines + 1 then
                while true do
                    term.write("Inserting (. to stop): ")
                    local line = term.input(nil, true)
                    if line == "." then break end
                    table.insert(lines, n, line)
                    n = n + 1
                end
                table.insert(history, {":i", start, n})
                saved = false
            else
                term.write("Invalid line number.\n")
            end
        elseif tokens[1] == ":a" then
            local n = tonumber(tokens[2])
            local start = n
            if n and n >= 1 and n <= #lines + 1 then
                while true do
                    term.write("Inserting (. to stop): ")
                    local line = term.input(nil, true)
                    if line == "." then break end
                    table.insert(lines, n + 1, line)
                    n = n + 1
                end
                table.insert(history, {":a", start + 1, n + 1})
                saved = false
            else
                term.write("Invalid line number.\n")
            end
        elseif tokens[1] == ":r" then
            local n = tonumber(tokens[2])
            if n and n >= 1 and n <= #lines + 1 then
                term.write("Line to replace with: ")
                local line = term.input(nil, true)
                local prevLine = lines[n]
                lines[n] = line
                table.insert(history, {":r", prevLine, n})
                saved = false
            else
                term.write("Invalid line number.\n")
            end
        elseif tokens[1] == ":c" then
            table.insert(history, {":c", lines})
            lines = {}
            saved = false
        elseif tokens[1] == ":e" then
            local doNew = true
            if not kFs.exists(kFs.join(kFs.currentdir(), tokens[2])) then
                term.write("Invalid file")
                goto ende
            end
            if not saved then doNew = savePrompt() end
            if not doNew then break end
            table.insert(history, {":e", lines})
            lines = readFile(tokens[2])
            term.write("Loaded " .. tostring(#lines) .. " lines. Type :help for commands.\n")
            saved = false
            ::ende::
        elseif tokens[1] == ":u" then
            local command
            repeat
                local cmd = table.remove(history)
                if cmd[1] == ":d" then
                    table.insert(lines, cmd[3], cmd[2])
                    command = true
                elseif cmd[1] == ":i" or cmd[1] == ":a" then
                    for i = cmd[3], cmd[2], -1 do
                        table.remove(lines, i)
                    end
                    command = true
                elseif cmd[1] == ":r" then
                    lines[cmd[3]] = cmd[2]
                    command = true
                elseif cmd[1] == ":c" then
                    lines = cmd[2]
                    command = true
                elseif cmd[1] == ":e" then
                    lines = cmd[2]
                    command = true
                end
            until #history == 0 or command
            saved = false
        elseif input == ":help" then
            term.write([[
Commands:
  :q          Quit
  :w          Save
  :p <s> <e>  Print buffer from <s> to <e>
  :d <n>      Delete line <n>
  :i <n>      Insert line before <n>
  :u          Undo
  :r <n>      Replace line
  :a <n>      Insert line after <n>
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
