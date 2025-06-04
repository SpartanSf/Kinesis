local ffi = require "ffi"

ffi.cdef[[
/* forward declarations */
typedef struct _TTF_Font TTF_Font;
typedef struct SDL_Surface SDL_Surface;
typedef uint32_t Uint32;
typedef uint8_t  Uint8;

/* SDL_Color (as used by SDL2_ttf) */
typedef struct {
    Uint8 r;
    Uint8 g;
    Uint8 b;
    Uint8 a;
} SDL_Color;

/* Initialization/Quitting */
int    TTF_Init(void);
void   TTF_Quit(void);
int    TTF_WasInit(void);

/* Opening/Closing a font */
TTF_Font* TTF_OpenFont(const char* file, int ptsize);
void      TTF_CloseFont(TTF_Font* font);

/* Font styles & metrics */
int       TTF_GetFontStyle(TTF_Font* font);
void      TTF_SetFontStyle(TTF_Font* font, int style);
int       TTF_GetFontOutline(TTF_Font* font);
void      TTF_SetFontOutline(TTF_Font* font, int outline);
int       TTF_FontHeight(TTF_Font* font);
int       TTF_FontAscent(TTF_Font* font);
int       TTF_FontDescent(TTF_Font* font);
int       TTF_FontLineSkip(TTF_Font* font);
int       TTF_FontFaces(TTF_Font* font);
int       TTF_FontFaceIsFixedWidth(TTF_Font* font);
const char* TTF_FontFaceFamilyName(TTF_Font* font);
const char* TTF_FontFaceStyleName(TTF_Font* font);
int         TTF_GlyphIsProvided(TTF_Font* font, Uint16 ch);
int         TTF_SizeText(TTF_Font* font, const char* text, int* w, int* h);

/* Basic rendering (solid / shaded / blended) */
SDL_Surface* TTF_RenderText_Solid(TTF_Font* font, const char* text, SDL_Color fg);
SDL_Surface* TTF_RenderUTF8_Solid(TTF_Font* font, const char* text, SDL_Color fg);

SDL_Surface* TTF_RenderText_Shaded(TTF_Font* font, const char* text, SDL_Color fg, SDL_Color bg);
SDL_Surface* TTF_RenderUTF8_Shaded(TTF_Font* font, const char* text, SDL_Color fg, SDL_Color bg);

SDL_Surface* TTF_RenderText_Blended(TTF_Font* font, const char* text, SDL_Color fg);
SDL_Surface* TTF_RenderUTF8_Blended(TTF_Font* font, const char* text, SDL_Color fg);

/* Wrapped variants */
SDL_Surface* TTF_RenderText_Solid_Wrapped(TTF_Font* font, const char* text, SDL_Color fg, Uint32 wrapLength);
SDL_Surface* TTF_RenderUTF8_Solid_Wrapped(TTF_Font* font, const char* text, SDL_Color fg, Uint32 wrapLength);

SDL_Surface* TTF_RenderText_Shaded_Wrapped(TTF_Font* font, const char* text, SDL_Color fg, SDL_Color bg, Uint32 wrapLength);
SDL_Surface* TTF_RenderUTF8_Shaded_Wrapped(TTF_Font* font, const char* text, SDL_Color fg, SDL_Color bg, Uint32 wrapLength);

SDL_Surface* TTF_RenderText_Blended_Wrapped(TTF_Font* font, const char* text, SDL_Color fg, Uint32 wrapLength);
SDL_Surface* TTF_RenderUTF8_Blended_Wrapped(TTF_Font* font, const char* text, SDL_Color fg, Uint32 wrapLength);
]]

-- On Windows it'll typically be SDL2_ttf.dll,
-- on Linux/macOS it might be libSDL2_ttf.so / libSDL2_ttf.dylib
local ttf = ffi.load("./lib/SDL2_ttf.dll")
return ttf
