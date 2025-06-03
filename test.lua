local ffi = require("ffi")
local sdl = require("lib/sdl2_ffi")
local ttf = require("lib/sdl2_ttf")
local gl = require("lib/gl")

assert(sdl.SDL_Init(sdl.SDL_INIT_VIDEO) == 0, ffi.string(sdl.SDL_GetError()))
assert(ttf.TTF_Init() == 0)

local window = sdl.SDL_CreateWindow("Hello",
    sdl.SDL_WINDOWPOS_CENTERED, sdl.SDL_WINDOWPOS_CENTERED,
    800, 600, sdl.SDL_WINDOW_SHOWN)

local renderer = sdl.SDL_CreateRenderer(window, -1,
    sdl.SDL_RENDERER_ACCELERATED + sdl.SDL_RENDERER_PRESENTVSYNC)

local font = ttf.TTF_OpenFont("assets/fontfile.ttf", 20)
assert(font ~= nil, "Failed to load font")

local white = ffi.new("SDL_Color", {255, 255, 255, 255})
local surface = ttf.TTF_RenderText_Solid(font, "Hello, world!", white)
assert(surface ~= nil, "Failed to render text")

local texture = sdl.SDL_CreateTextureFromSurface(renderer, surface)
local w, h = ffi.new("int[1]"), ffi.new("int[1]")
sdl.SDL_QueryTexture(texture, nil, nil, w, h)
sdl.SDL_FreeSurface(surface)

local dst = ffi.new("SDL_Rect")
dst.x = 0
dst.y = 0
dst.w, dst.h = w[0], h[0]

local event = ffi.new("SDL_Event")
local running = true
while running do
    while sdl.SDL_PollEvent(event) ~= 0 do
        if event.type == sdl.SDL_QUIT then running = false end
    end

    sdl.SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255)
    sdl.SDL_RenderClear(renderer)
    sdl.SDL_RenderCopy(renderer, texture, nil, dst)
    sdl.SDL_RenderPresent(renderer)
end

sdl.SDL_DestroyTexture(texture)
ttf.TTF_CloseFont(font)
sdl.SDL_DestroyRenderer(renderer)
sdl.SDL_DestroyWindow(window)

ttf.TTF_Quit()
sdl.SDL_Quit()

