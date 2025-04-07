#include <SDL2/SDL.h>
#include <SDL2/SDL_stdinc.h>
#include <SDL2/SDL_ttf.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <complex.h>

#include <time.h>

#include "graphics.h"
#include "fps.h"
#include "test.h"


int main(int argc, char *argv[]) 
{
        sdl_state_t state = { 0 };

        if(initialize_sdl(&state))
                return 1;

        fps_counter_t fps_counter = { 0 };
        init_fps_counter(&fps_counter);

        test_all(&state, &fps_counter);

        // run_mandelbrot(&state, &fps_counter, 0, render_mandelbrot_intrinsics);

        deinitialize_sdl(&state);
        return 0;
}
