#include <SDL2/SDL.h>
#include <SDL2/SDL_stdinc.h>
#include <SDL2/SDL_ttf.h>

#include "fps.h"
#include "graphics.h"


void init_fps_counter(fps_counter_t* counter) 
{
        counter->frames = 0;
        counter->last_time = SDL_GetTicks();
        counter->fps = 0.0f;
}

float update_fps_counter(fps_counter_t* counter) 
{
        counter->frames++;

        Uint32 current_time = SDL_GetTicks();
        if ((current_time - counter->last_time) >= 1000) 
        {
                counter->fps = counter->frames / 
                        ((current_time - counter->last_time) / 1000.0f);
                counter->frames = 0;
                counter->last_time = current_time;
        }

        return counter->fps;
}

void render_fps_counter(sdl_state_t* state, fps_counter_t* counter) 
{
        char fps_text[50] = { 0 };

        sprintf(fps_text, "FPS: %.0f", counter->fps);

        SDL_Color color = { 255, 255, 255 };

        SDL_Surface* surface = TTF_RenderText_Solid(state->font, fps_text, color);
        SDL_Texture* texture = SDL_CreateTextureFromSurface(state->renderer, surface);

        SDL_Rect rect = { 10, 10, surface->w, surface->h };

        SDL_RenderCopy(state->renderer, texture, NULL, &rect);

        SDL_FreeSurface(surface);
        SDL_DestroyTexture(texture);
}

