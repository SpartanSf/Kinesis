local ffi = require("ffi")

ffi.cdef[[
typedef struct SDL_Surface SDL_Surface;

SDL_Surface* IMG_Load(const char *file);
]]

local img = ffi.load("./lib/SDL2_image.dll")

return {
  IMG_Load = img.IMG_Load,
}

