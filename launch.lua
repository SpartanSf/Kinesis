local path = "launch.lua"

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
local ffi = require("ffi")
local sdl = require("lib.sdl2_ffi")
local ttf = require("lib.sdl2_ttf")

local computerID

assert(sdl.SDL_Init(sdl.SDL_INIT_VIDEO) == 0, "SDL_Init failed")
assert(ttf.TTF_Init() == 0, "TTF_Init failed")

local window = sdl.SDL_CreateWindow("Input Dialog",
    sdl.SDL_WINDOWPOS_CENTERED, sdl.SDL_WINDOWPOS_CENTERED,
    500, 150,
    sdl.SDL_WINDOW_SHOWN)
assert(window ~= nil, "Window creation failed")

local renderer = sdl.SDL_CreateRenderer(window, -1, sdl.SDL_RENDERER_ACCELERATED)
assert(renderer ~= nil, "Renderer creation failed")

local font_path = "assets/fontfile.ttf"
local font_size = 20
local font = ttf.TTF_OpenFont(font_path, font_size)
assert(font ~= nil, "Failed to open font")

local input_text = ""
local cursor_visible = true
local cursor_timer = 0
local cursor_blink_delay = 0.5

local button_rect = ffi.new("SDL_Rect")
button_rect.x = 400
button_rect.y = 50
button_rect.w = 80
button_rect.h = 30

local input_rect = ffi.new("SDL_Rect")
input_rect.x = 20
input_rect.y = 50
input_rect.w = 360
input_rect.h = 30

local white = {255, 255, 255, 255}
local black = {0, 0, 0, 255}
local gray = {200, 200, 200, 255}
local blue = {100, 149, 237, 255}

local function setDrawColor(rgba)
    sdl.SDL_SetRenderDrawColor(renderer, rgba[1], rgba[2], rgba[3], rgba[4])
end

local function renderText(text, color)
    local surface = ttf.TTF_RenderUTF8_Blended(font, text, color)
    if surface == nil then
        error("Failed to create text surface: " .. ffi.string(sdl.SDL_GetError()))
    end
    local texture = sdl.SDL_CreateTextureFromSurface(renderer, surface)
    sdl.SDL_FreeSurface(surface)
    return texture
end

local function getTextureSize(tex)
    local w, h = ffi.new("int[1]"), ffi.new("int[1]")
    sdl.SDL_QueryTexture(tex, nil, nil, w, h)
    return w[0], h[0]
end

local function fillRect(rect, color)
    setDrawColor(color)
    sdl.SDL_RenderFillRect(renderer, rect)
end

local function drawRect(rect, color)
    setDrawColor(color)
    sdl.SDL_RenderDrawRect(renderer, rect)
end

local running = true
local event = ffi.new("SDL_Event")
local keyboard_active = true

sdl.SDL_StartTextInput()

while running do
    while sdl.SDL_PollEvent(event) ~= 0 do
        if event.type == sdl.SDL_QUIT then
            running = false
        elseif event.type == sdl.SDL_TEXTINPUT then
            if keyboard_active then
                input_text = input_text .. ffi.string(event.text.text)
            end
        elseif event.type == sdl.SDL_KEYDOWN then
            local key = event.key.keysym.sym
            if key == sdl.SDLK_BACKSPACE then
                local bytepos = #input_text
                if bytepos > 0 then
                    while bytepos > 0 and (bit.band(input_text:byte(bytepos), 0xC0)) == 0x80 do
                        bytepos = bytepos - 1
                    end
                    input_text = input_text:sub(1, bytepos - 1)
                end
            elseif key == sdl.SDLK_RETURN or key == sdl.SDLK_KP_ENTER then
                computerID = input_text
                running = false
                input_text = ""
            end
        elseif event.type == sdl.SDL_MOUSEBUTTONDOWN then
            local x, y = event.button.x, event.button.y
            if x >= button_rect.x and x <= button_rect.x + button_rect.w and
               y >= button_rect.y and y <= button_rect.y + button_rect.h then
                computerID = input_text

                input_text = ""
            end
        end
    end

    setDrawColor(white)
    sdl.SDL_RenderClear(renderer)

    fillRect(input_rect, gray)
    drawRect(input_rect, black)

    local display_text = input_text
    cursor_timer = cursor_timer + 0.016
    if cursor_timer >= cursor_blink_delay then
        cursor_visible = not cursor_visible
        cursor_timer = 0
    end
    if display_text == "" then
        display_text = " "
    end
    if cursor_visible then
        display_text = display_text .. "_"
    end


    local text_color = ffi.new("SDL_Color", black[1], black[2], black[3], black[4])
    local text_tex = renderText(display_text, text_color)
    local tw, th = getTextureSize(text_tex)
    local text_dst = ffi.new("SDL_Rect", input_rect.x + 5, input_rect.y + math.floor((input_rect.h - th) / 2), tw, th)
    sdl.SDL_RenderCopy(renderer, text_tex, nil, text_dst)
    sdl.SDL_DestroyTexture(text_tex)

    fillRect(button_rect, blue)
    drawRect(button_rect, black)

    local btn_text_tex = renderText("Submit", ffi.new("SDL_Color", 255,255,255,255))
    local btn_tw, btn_th = getTextureSize(btn_text_tex)
    local btn_text_dst = ffi.new("SDL_Rect", button_rect.x + math.floor((button_rect.w - btn_tw) / 2), button_rect.y + math.floor((button_rect.h - btn_th) / 2), btn_tw, btn_th)
    sdl.SDL_RenderCopy(renderer, btn_text_tex, nil, btn_text_dst)
    sdl.SDL_DestroyTexture(btn_text_tex)

    sdl.SDL_RenderPresent(renderer)

    sdl.SDL_Delay(16)
end

sdl.SDL_StopTextInput()
ttf.TTF_CloseFont(font)
sdl.SDL_DestroyRenderer(renderer)
sdl.SDL_DestroyWindow(window)
ttf.TTF_Quit()
sdl.SDL_Quit()

local function runFileShell(path, args)
  local file = io.open(lfs.currentdir() .. "/" .. path, "r")
  local code = file:read("*a")
  file:close()

  if code:match("^%s*$") then
    return false, "Script is empty"
  end

  local chunk, err = loadstring(code, "@" .. path)
  if not chunk then
    return error("Syntax error: " .. err)
  end

  local fullEnv = getfenv(2)
  fullEnv.__PROVENV_ID = args
  setmetatable(fullEnv, { __index = _G })
  setfenv(chunk, fullEnv)

  local ok, result = pcall(chunk)
  if not ok then
    error("Runtime error: " .. result)
  end

  return true, result
end

runFileShell("kinesis.lua", computerID)
