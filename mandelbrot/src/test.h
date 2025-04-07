#pragma once

#include <SDL2/SDL.h>
#include <SDL2/SDL_stdinc.h>
#include <SDL2/SDL_ttf.h>

#include "graphics.h"
#include "fps.h"

void run_mandelbrot(sdl_state_t* state, fps_counter_t* fps_counter, size_t iter_cnt,
                        void(*render_mandelbrot)(sdl_state_t* state, float x_offset, float y_offset, float zoom_factor));

void measure(sdl_state_t* state, fps_counter_t* fps_counter, 
                void(*render_mandelbrot)(sdl_state_t* state, float x_offset, float y_offset, float zoom_factor));

void test_all(sdl_state_t* state, fps_counter_t* fps_counter);

