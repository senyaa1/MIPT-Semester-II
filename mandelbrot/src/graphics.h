#pragma once

#include <SDL2/SDL.h>
#include <SDL2/SDL_stdinc.h>
#include <SDL2/SDL_ttf.h>

#define WIDTH           800
#define HEIGHT          600
#define MAX_ITER        255
#define FPS_FONT        "Tektur-Medium.ttf"

typedef struct sdl_state
{
        SDL_Window*     window;
        SDL_Renderer*   renderer;
        SDL_Texture*    texture;
        TTF_Font*       font;
        Uint32*         pixels;
} sdl_state_t;


void deinitialize_sdl(sdl_state_t* state);
int initialize_sdl(sdl_state_t* state);
Uint32 get_color(int iter);
void render_mandelbrot(sdl_state_t* state, double x_offset, double y_offset, double zoom_factor);

