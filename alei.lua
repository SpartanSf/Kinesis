local ffi = require("ffi")

ffi.cdef[[
int putchar(int c);
int fflush(void *stream);
]]

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
    if type(data) ~= "number" or data < 0 or data > 0xFF then
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

local function writeChannelIo(data)
    ffi.C.putchar(bit.band(data, 0xFF))
    ffi.C.fflush(nil)
end

ioControl.listen(0, writeChannelIo)



local text = "Hello, world!"
for i = 1, #text do
    ioControl.put(0, text:byte(i))
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
    },
    math = {
        abs = math.abs,
        sin = math.sin,
        cos = math.cos,
        random = math.random,
        floor = math.floor,
    },
    string = {
        sub = string.sub,
        len = string.len,
        find = string.find,
        gsub = string.gsub,
    },
    coroutine = coroutine,
    ioControl = ioControl,
}

