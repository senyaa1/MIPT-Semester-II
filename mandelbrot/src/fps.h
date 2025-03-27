#pragma once

#include <SDL2/SDL.h>
#include <SDL2/SDL_stdinc.h>
#include <SDL2/SDL_ttf.h>

#include "graphics.h"

typedef struct fps_counter
{
        Uint32 frames;
        Uint32 last_time;
        float fps;
} fps_counter_t;

void init_fps_counter(fps_counter_t* counter);
float update_fps_counter(fps_counter_t* counter);
void render_fps_counter(sdl_state_t* state, fps_counter_t* counter);
