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


void run_mandelbrot(sdl_state_t* state, fps_counter_t* fps_counter, size_t iter_cnt,
                        void(*render_mandelbrot)(sdl_state_t* state, float x_offset, float y_offset, float zoom_factor))
{
        int running = 1;
        float cur_x_offs = 0, cur_y_offs = 0, zoom_factor = 1.;
        SDL_Event event;

        float x_speed = 0.1, y_speed = 0.1, zoom_speed = 1.1;
        size_t iterations = 0;
        while (running && (iterations < iter_cnt || !iter_cnt))
        {
                while (SDL_PollEvent(&event)) 
                        if (event.type == SDL_QUIT) 
                                running = 0;

                const Uint8 *keyboard_state = SDL_GetKeyboardState(NULL);
                if (keyboard_state[SDL_SCANCODE_W])     cur_y_offs -= (y_speed * zoom_factor);
                if (keyboard_state[SDL_SCANCODE_S])     cur_y_offs += (y_speed * zoom_factor);
                if (keyboard_state[SDL_SCANCODE_A])     cur_x_offs -= (x_speed * zoom_factor);
                if (keyboard_state[SDL_SCANCODE_D])     cur_x_offs += (x_speed * zoom_factor);

                if (keyboard_state[SDL_SCANCODE_Q])     zoom_factor /= zoom_speed;
                if (keyboard_state[SDL_SCANCODE_E])     zoom_factor *= zoom_speed;

                render_mandelbrot(state, cur_x_offs, cur_y_offs, zoom_factor);

                update_fps_counter(fps_counter);

                SDL_UpdateTexture(state->texture, NULL, state->pixels, WIDTH * sizeof(Uint32));
                SDL_RenderClear(state->renderer);
                SDL_RenderCopy(state->renderer, state->texture, NULL, NULL);
                render_fps_counter(state, fps_counter);
                SDL_RenderPresent(state->renderer);

                iterations++;
                SDL_Delay(16);
        }

}

void measure(sdl_state_t* state, fps_counter_t* fps_counter, 
                void(*render_mandelbrot)(sdl_state_t* state, float x_offset, float y_offset, float zoom_factor))
{
        uint64_t begin_rtdsc =  __rdtsc();
	clock_t start = clock();
        run_mandelbrot(state, fps_counter, 100, render_mandelbrot);
        uint64_t end_rdtsc =  __rdtsc();
	clock_t end = clock();

	double elapsed = ((double)(end - start)) / CLOCKS_PER_SEC;
        printf("Clocks: %ld\t; Time: %g\n" , end_rdtsc - begin_rtdsc, elapsed);
}


void test_all(sdl_state_t* state, fps_counter_t* fps_counter)
{
        printf("Naive: \n");
        measure(state, fps_counter, render_mandelbrot_default);
        printf("Parallelized: \n");
        measure(state, fps_counter, render_mandelbrot_parallelized);
        printf("Intrinsics: \n");
        measure(state, fps_counter, render_mandelbrot_intrinsics);
}
