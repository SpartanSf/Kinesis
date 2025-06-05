local ffi = require("ffi")
local sdl = require("lib.sdl2_ffi")
local ttf = require("lib.sdl2_ttf")

local textdraw = {}
textdraw.__index = textdraw

function textdraw.new(renderer, font_path, font_size, text_color)
    if ttf.TTF_WasInit() == 0 then
        assert(ttf.TTF_Init() == 0, "TTF_Init failed: " .. ffi.string(sdl.SDL_GetError()))
    end

    local font = ttf.TTF_OpenFont(font_path, font_size)
    assert(font ~= nil, "Failed to load font: " .. font_path)

    local self = setmetatable({
        font = font,
        renderer = renderer,
        cache = {},
        font_size = font_size,
        text_color = text_color or ffi.new("SDL_Color", {255, 255, 255, 255}),
    }, textdraw)

    self:_prerender_ascii()
    return self
end

function textdraw:_prerender_ascii()
    for i = 32, 126 do
        local char = string.char(i)
        local surface = ttf.TTF_RenderText_Solid(self.font, char, self.text_color)
        assert(surface ~= nil, "Failed to render char: " .. char)

        local texture = sdl.SDL_CreateTextureFromSurface(self.renderer, surface)
        assert(texture ~= nil, "Failed to create texture for char: " .. char)

        local entry = {
            texture = texture,
            w = surface.w,
            h = surface.h,
        }

        self.cache[char] = entry
        sdl.SDL_FreeSurface(surface)
    end
end

function textdraw:draw_char(char, x, y)
    local entry = self.cache[char]
    if not entry then return end

    local dst = ffi.new("SDL_Rect", {
        x = x,
        y = y,
        w = entry.w,
        h = entry.h,
    })

    sdl.SDL_RenderCopy(self.renderer, entry.texture, nil, dst)
end

function textdraw:draw_grid_char(char, cell_x, cell_y, mod_x, mod_y)
    local char_width = self:get_char_width()
    local char_height = self:get_char_height()
    local x = cell_x * char_width * (mod_x or 1)
    local y = cell_y * char_height * (mod_y or 1)
    self:draw_char(char, x, y)
end

function textdraw:clear_cache()
    for _, entry in pairs(self.cache) do
        sdl.SDL_DestroyTexture(entry.texture)
    end
    self.cache = {}
end

function textdraw:destroy()
    self:clear_cache()
    ttf.TTF_CloseFont(self.font)
end

function textdraw:get_char_width()
    local entry = self.cache['W'] or next(self.cache)
    if entry then
        return entry.w
    else
        return self.font_size
    end
end

function textdraw:get_char_height()
    local entry = self.cache['W'] or next(self.cache)
    if entry then
        return entry.h
    else
        return self.font_size
    end
end

return textdraw

