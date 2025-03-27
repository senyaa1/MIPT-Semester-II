#include <SDL2/SDL.h>
#include <SDL2/SDL_stdinc.h>
#include <SDL2/SDL_ttf.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <complex.h>

#include "graphics.h"
#include "fps.h"

int main(int argc, char *argv[]) 
{
        sdl_state_t state = { 0 };

        if(initialize_sdl(&state))
                return 1;

        fps_counter_t fps_counter = { 0 };
        init_fps_counter(&fps_counter);

        int running = 1;
        double cur_x_offs = 0, cur_y_offs = 0, zoom_factor = 1.;
        SDL_Event event;

        double x_speed = 0.1, y_speed = 0.1, zoom_speed = 1.1;
        while (running) 
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

                render_mandelbrot(&state, cur_x_offs, cur_y_offs, zoom_factor);
                update_fps_counter(&fps_counter);


                SDL_UpdateTexture(state.texture, NULL, state.pixels, WIDTH * sizeof(Uint32));
                SDL_RenderClear(state.renderer);
                SDL_RenderCopy(state.renderer, state.texture, NULL, NULL);
                render_fps_counter(&state, &fps_counter);
                SDL_RenderPresent(state.renderer);

                SDL_Delay(16);
        }

        deinitialize_sdl(&state);
        return 0;
}
