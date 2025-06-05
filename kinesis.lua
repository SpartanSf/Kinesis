local path = arg and arg[0] or debug.getinfo(2, "S").source:sub(2)

if not path:match("^/") and not path:match("^[A-Za-z]:[\\/]") then
    local popen_cmd = package.config:sub(1,1) == "\\" and "cd" or "pwd"
    local handle = io.popen(popen_cmd)
    local cwd = handle:read("*l")
    handle:close()
    path = cwd .. "/" .. path
end

path = path:gsub("\\", "/")

local sysroot = path:match("(.*/)") .. "systree"

package.path = sysroot .. "/share/lua/5.1/?.lua;" ..
               sysroot .. "/share/lua/5.1/?/init.lua;" ..
               package.path

package.cpath = sysroot .. "/lib/lua/5.1/?.dll;" ..
                package.cpath

local ffi = require("ffi")
local lfs = require("lfs")
local serpent = require("serpent")
local luapath = require("path")
local sdl = require("lib.sdl2_ffi")
local textdraw = require("lib.textdraw")
local image = require("lib.sdl2_image")
local json = require("lib.json")

local id, spec
    repeat
    print("Enter a computer ID")
    local userInput = io.read()

    local nPath = luapath.join(lfs.currentdir(), "systems", userInput)
    if lfs.attributes(nPath) then
        id = luapath.normalize(nPath)
        spec = luapath.normalize(userInput)
    end
until id

assert(sdl.SDL_Init(sdl.SDL_INIT_VIDEO) == 0)

local window = sdl.SDL_CreateWindow("Computer "..tostring(spec),
    sdl.SDL_WINDOWPOS_CENTERED, sdl.SDL_WINDOWPOS_CENTERED,
    640, 480, bit.bor(sdl.SDL_WINDOW_SHOWN, sdl.SDL_WINDOW_RESIZABLE))

sdl.SDL_RaiseWindow(window)

local surface = image.IMG_Load("assets/logo.png")
sdl.SDL_SetWindowIcon(window, surface)
sdl.SDL_FreeSurface(surface)

local renderer = sdl.SDL_CreateRenderer(window, -1,
    sdl.SDL_RENDERER_ACCELERATED + sdl.SDL_RENDERER_PRESENTVSYNC)

local drawer = textdraw.new(renderer, "assets/fontfile.ttf", 16)

local window_width = ffi.new("int[1]")
local window_height = ffi.new("int[1]")
sdl.SDL_GetWindowSize(window, window_width, window_height)

local ioControl = {}
local ioChannel = {}
local ioListeners = {}

for i = 0, 0xFF do
    ioListeners[i] = {}
end

local function checkChannel(channel)
    if type(channel) ~= "number" or channel < 0 or channel > 0xFF then
        error("Invalid channel ID, must be 8-bit: " .. tostring(channel), 0)
    end
end

local function checkData(data)
    if type(data) ~= "number" or data < 0 or data > 0xFFFF then
        error("Data must be 16-bit: " .. tostring(data), 0)
    end
end

function ioControl.put(channel, data)
    checkChannel(channel)
    checkData(data)

    ioChannel[channel] = data
    for _, listener in ipairs(ioListeners[channel]) do
        listener(data)
    end
end

function ioControl.get(channel)
    checkChannel(channel)

    local data = ioChannel[channel] or 0
    ioChannel[channel] = 0
    return data
end

function ioControl.peek(channel)
    checkChannel(channel)

    return ioChannel[channel] or 0
end

function ioControl.listen(channel, listener)
    checkChannel(channel)
    if type(listener) ~= "function" then
        error("Listener must be a function", 0)
    end

    table.insert(ioListeners[channel], listener)
end

function ioControl.unListen(channel, name)
    checkChannel(channel)
    local listeners = ioListeners[channel]
    for i = #listeners, 1, -1 do
        if listeners[i] == name then
            table.remove(listeners, i)
            break
        end
    end
end

local window_width = ffi.new("int[1]")
local window_height = ffi.new("int[1]")
sdl.SDL_GetWindowSize(window, window_width, window_height)

local char_width = drawer:get_char_width()
local char_height = drawer:get_char_height()
local cols = math.floor((window_width[0] / char_width) / 1.1)
local rows = math.floor(window_height[0] / char_height)

local char_buffer = {}
for i = 1, rows do
    char_buffer[i] = {}
end

local function scroll(charBuffer)
    for i = 1, #charBuffer - 1 do
        charBuffer[i] = charBuffer[i + 1]
    end
    charBuffer[#charBuffer] = {}
end

local current_row = 1
local current_col = 1
local waitDataCurX = false
local waitDataCurY = false

local function writeChannelIo(data)
    local window_width = ffi.new("int[1]")
    local window_height = ffi.new("int[1]")
    sdl.SDL_GetWindowSize(window, window_width, window_height)

    local char_width = drawer:get_char_width()
    local char_height = drawer:get_char_height()
    local cols = math.floor((window_width[0] / char_width) / 1.1)
    local rows = math.floor((window_height[0] / char_height) / 1.1)

    if data == 0xFF80 then
        waitDataCurX = true
    elseif waitDataCurX then
        current_col = data
        waitDataCurX = false
    elseif data == 0xFF81 then
        waitDataCurY = true
    elseif waitDataCurY then
        current_row = data - 1
        waitDataCurY = false
    elseif data == 0xFF82 then
        ioControl.put(1, cols)
    elseif data == 0xFF83 then
        ioControl.put(1, rows)
    elseif data == 0xFF84 then
        ioControl.put(1, current_col)
    elseif data == 0xFF85 then
        ioControl.put(1, current_row)
    elseif data and data ~= string.byte("\n") and data == bit.band(tonumber(data) or 0, 0xFF) then
        local char = string.char(data)

        if not char_buffer[current_row] then
            char_buffer[current_row] = {}
        end

        table.insert(char_buffer[current_row], char)
        current_col = current_col + 1

        if current_col > cols then
            current_row = current_row + 1
            current_col = 1

            if current_row > rows then
                scroll(char_buffer)
                current_row = rows
            end
        end
    elseif data == string.byte("\n") then
        current_row = current_row + 1
        current_col = 1
        if current_row <= rows then
            char_buffer[current_row] = {}
        end
    elseif data == 0xFF33 then
        if current_col > 1 then
            table.remove(char_buffer[current_row], current_col - 1)
            current_col = current_col - 1
        elseif current_row > 1 then
            current_row = current_row - 1
            current_col = #char_buffer[current_row] + 1
            table.remove(char_buffer[current_row], current_col - 1)
            current_col = current_col - 1
        end
    end
    if current_row > rows then
        scroll(char_buffer)
        current_row = rows
    end
end

ioControl.listen(0, writeChannelIo)

local kFs = {}

local function getPath(path)
    local sandboxRoot = luapath.join(id, "system")
    sandboxRootN = luapath.normalize(sandboxRoot:match("^(.-)/?$") .. "/")

    local joinedPath = luapath.join(sandboxRoot, path)
    local normalized = luapath.normalize(joinedPath)

    if normalized:sub(1, #sandboxRootN) ~= sandboxRootN then
        error("Access outside sandbox is forbidden: " .. path, 0)
    end

    return normalized
end

function kFs.chdir(path)
    return lfs.chdir(getPath(path))
end

function kFs.currentdir()
    local sandboxRoot = luapath.join(id, "system")
    local sandboxRootN = luapath.normalize(sandboxRoot:match("^(.-)/?$") .. "/")

    local current = luapath.normalize(lfs.currentdir())

    if current:sub(1, #sandboxRootN) == sandboxRootN then
        local relative = current:sub(#sandboxRootN + 1)
        return relative == "" and "." or relative
    else
        error("Current directory is outside sandbox: " .. current, 0)
    end
end

function kFs.exists(path)
    return lfs.attributes(getPath(path)) ~= nil
end

function kFs.list(path)
    local files = {}
    for file in lfs.dir(getPath(path)) do
        if file ~= "." and file ~= ".." then table.insert(files, file) end
    end
    return files
end

function kFs.isDir(path)
    local attr = lfs.attributes(getPath(path))

    if attr and attr.mode == "directory" then
        return true
    else
        return false
    end
end

function kFs.open(path, mode)
    return io.open(getPath(path), mode)
end

local function delete_recursive(path)
    local attr = lfs.attributes(path)
    if not attr then return false, "Path does not exist" end

    if attr.mode == "directory" then
        for entry in lfs.dir(path) do
            if entry ~= "." and entry ~= ".." then
                local full_path = path .. "/" .. entry
                local ok, err = delete_recursive(full_path)
                if not ok then return false, err end
            end
        end
        return os.remove(path)
    else
        return os.remove(path)
    end
end

function kFs.delete(path)
    delete_recursive(getPath(path))
    return lfs.rmdir(getPath(path))
end

function kFs.mkdir(path)
    return lfs.mkdir(getPath(path))
end

function kFs.normalize(path)
    return luapath.normalize(path)
end

function kFs.join(...)
    return luapath.join(...)
end

function kFs.times(path)
    return luapath.ctime(getPath(path)), luapath.mtime(getPath(path)), luapath.atime(getPath(path))
end

function kFs.splitext(path)
    return luapath.splitext(path)
end

function kFs.splitpath(path)
    return luapath.splitpath(path)
end

function kFs.copy(src, dest)
    return luapath.copy(getPath(src), getPath(dest))
end

function kFs.rename(src, dest)
    return luapath.rename(getPath(src), getPath(dest)) 
end

function kFs.move(src, dest)
    local srcFile = kFs.open(src, "r")
    local destFile = kFs.open(dest, "w")
    destFile:write(srcFile:read("*a"))
    srcFile:close()
    destFile:close()
end

function kFs.getSize(path)
    return luapath.size(getPath(path))
end

local kOs = {}

function kOs.getDate(timestamp)
    return os.date("%Y-%m-%d %H:%M:%S", timestamp)
end

local function handleKey(channel, key)
    if key == sdl.SDLK_LSHIFT then
        ioControl.put(channel, 0xFF00)
    elseif key == sdl.SDLK_RSHIFT then
        ioControl.put(channel, 0xFF01)
    elseif key == sdl.SDLK_LCTRL then
        ioControl.put(channel, 0xFF02)
    elseif key == sdl.SDLK_RCTRL then
        ioControl.put(channel, 0xFF03)
    elseif key == sdl.SDLK_LALT then
        ioControl.put(channel, 0xFF04)
    elseif key == sdl.SDLK_RALT then
        ioControl.put(channel, 0xFF05)
    elseif key == sdl.SDLK_LGUI then
        ioControl.put(channel, 0xFF06)
    elseif key == sdl.SDLK_RGUI then
        ioControl.put(channel, 0xFF07)
    elseif key == sdl.SDLK_UP then
        ioControl.put(channel, 0xFF10)
    elseif key == sdl.SDLK_DOWN then
        ioControl.put(channel, 0xFF11)
    elseif key == sdl.SDLK_LEFT then
        ioControl.put(channel, 0xFF12)
    elseif key == sdl.SDLK_RIGHT then
        ioControl.put(channel, 0xFF13)
    elseif key == sdl.SDLK_HOME then
        ioControl.put(channel, 0xFF14)
    elseif key == sdl.SDLK_END then
        ioControl.put(channel, 0xFF15)
    elseif key == sdl.SDLK_PAGEUP then
        ioControl.put(channel, 0xFF16)
    elseif key == sdl.SDLK_PAGEDOWN then
        ioControl.put(channel, 0xFF17)
    elseif key == sdl.SDLK_INSERT then
        ioControl.put(channel, 0xFF18)
    elseif key == sdl.SDLK_DELETE then
        ioControl.put(channel, 0xFF19)
    elseif key == sdl.SDLK_F1 then
        ioControl.put(channel, 0xFF20)
    elseif key == sdl.SDLK_F2 then
        ioControl.put(channel, 0xFF21)
    elseif key == sdl.SDLK_F3 then
        ioControl.put(channel, 0xFF22)
    elseif key == sdl.SDLK_F4 then
        ioControl.put(channel, 0xFF23)
    elseif key == sdl.SDLK_F5 then
        ioControl.put(channel, 0xFF24)
    elseif key == sdl.SDLK_F6 then
        ioControl.put(channel, 0xFF25)
    elseif key == sdl.SDLK_F7 then
        ioControl.put(channel, 0xFF26)
    elseif key == sdl.SDLK_F8 then
        ioControl.put(channel, 0xFF27)
    elseif key == sdl.SDLK_F9 then
        ioControl.put(channel, 0xFF28)
    elseif key == sdl.SDLK_F10 then
        ioControl.put(channel, 0xFF29)
    elseif key == sdl.SDLK_F11 then
        ioControl.put(channel, 0xFF2A)
    elseif key == sdl.SDLK_F12 then
        ioControl.put(channel, 0xFF2B)
    elseif key == sdl.SDLK_ESCAPE then
        ioControl.put(channel, 0xFF30)
    elseif key == sdl.SDLK_TAB then
        ioControl.put(channel, 0xFF31)
    elseif key == sdl.SDLK_RETURN then
        ioControl.put(channel, 0xFF32)
    elseif key == sdl.SDLK_BACKSPACE then
        ioControl.put(channel, 0xFF33)
    elseif key == sdl.SDLK_CAPSLOCK then
        ioControl.put(channel, 0xFF34)
    elseif key == sdl.SDLK_PRINTSCREEN then
        ioControl.put(channel, 0xFF35)
    elseif key == sdl.SDLK_SCROLLLOCK then
        ioControl.put(channel, 0xFF36)
    elseif key == sdl.SDLK_PAUSE then
        ioControl.put(channel, 0xFF37) -- 0xFF80 for setting cursor x. 0xFF81 for cursor y.
    else
        ioControl.put(channel, bit.band(key or 0, 0xFFFF))
    end
end

local safe_env = {
    type = type,
    tostring = tostring,
    tonumber = tonumber,
    pairs = pairs,
    ipairs = ipairs,
    table = {
        insert = table.insert,
        remove = table.remove,
        sort = table.sort,
        concat = table.concat,
    },
    math = {
        abs = math.abs,
        sin = math.sin,
        cos = math.cos,
        random = math.random,
        floor = math.floor,
        ceil = math.ceil,
        min = math.min,
        max = math.max,
    },
    string = {
        sub = string.sub,
        len = string.len,
        find = string.find,
        gsub = string.gsub,
        byte = string.byte,
        char = string.char,
        format = string.format,
        rep = string.rep,
        upper = string.upper,
        lower = string.lower
    },
    coroutine = coroutine,
    ioControl = ioControl,
    serpent = serpent,
    json = json,
    bit = bit,
    kFs = kFs,
    load = load,
    loadstring = loadstring,
    setmetatable = setmetatable,
    setfenv = setfenv,
    getfenv = getfenv,
    print = print,
    error = error,
    pcall = pcall,
    xpcall = xpcall,
    getSize = getSize,
    getDate = getDate,
    os = {
        getDate = kOs.getDate,
        time = os.time
    },
}
safe_env._G = safe_env

local event = ffi.new("SDL_Event")

local mainco = coroutine.create(function()
    local running = true
    while running do
        while sdl.SDL_PollEvent(event) ~= 0 do
            if event.type == sdl.SDL_QUIT then
                running = false
            elseif event.type == sdl.SDL_KEYDOWN then
                local key = event.key.keysym.sym
                handleKey(2, key)
            elseif event.type == sdl.SDL_KEYUP then
                local key = event.key.keysym.sym
                handleKey(3, key)
            end
        end

        sdl.SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255)
        sdl.SDL_RenderClear(renderer)

        sdl.SDL_GetWindowSize(window, window_width, window_height)

        local char_width = drawer:get_char_width()
        local char_height = drawer:get_char_height()
        local cols = math.floor(window_width[0] / char_width)
        local rows = math.floor(window_height[0] / char_height)

        for row = 1, rows do
            local line = char_buffer[row]
            if line then
                for col = 1, cols do
                    local char = line[col]
                    if char then
                        drawer:draw_grid_char(char, col - 1, row - 1, 1, 1)
                        --drawer:draw_grid_char(char, col - 1, row - 1, 22/30, 1)
                    end
                end
            end
        end

        sdl.SDL_RenderPresent(renderer)
        coroutine.yield()
    end
end)

local programco = coroutine.create(function()
    local chunk, err = loadfile(luapath.join(id, "eeprom.lua"))
    lfs.chdir(luapath.join(id, "system"))

    if not chunk then error(err) end
    setfenv(chunk, safe_env)
    chunk()
end)

local frameDelay = 1000 / 60
local lastFrameTime = sdl.SDL_GetTicks()

while true do
    if coroutine.status(mainco) == "dead" then
        print("Drawing coroutine died"); break
    elseif coroutine.status(programco) == "dead" then
        print("Program coroutine died"); break
    end

    local ok_prog, result_prog = coroutine.resume(programco)
    if not ok_prog then
        print("Coroutine error in script:", result_prog)
        break
    end

    local now = sdl.SDL_GetTicks()
    if now - lastFrameTime >= frameDelay then
        local ok_draw, result_draw = coroutine.resume(mainco)
        if not ok_draw then
            print("Coroutine error in drawing:", result_draw)
            break
        end
        lastFrameTime = now
    end
end
