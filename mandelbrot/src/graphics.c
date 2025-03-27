#include <SDL2/SDL.h>
#include <SDL2/SDL_stdinc.h>
#include <SDL2/SDL_ttf.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <complex.h>

#include "graphics.h"

void deinitialize_sdl(sdl_state_t* state)
{
        free(state->pixels);
        SDL_DestroyTexture(state->texture);
        SDL_DestroyRenderer(state->renderer);
        SDL_DestroyWindow(state->window);
        TTF_Quit();
        SDL_Quit();
}

int initialize_sdl(sdl_state_t* state)
{
        if (SDL_Init(SDL_INIT_VIDEO) != 0) 
        {
                fprintf(stderr, "SDL_Init Error: %s\n", SDL_GetError());
                return 1;
        }

        state->window = SDL_CreateWindow("Mandelbrot", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, WIDTH, HEIGHT, SDL_WINDOW_SHOWN);
        if (!state->window) 
        {
                fprintf(stderr, "SDL_CreateWindow Error: %s\n", SDL_GetError());
                deinitialize_sdl(state);
                return 1;
        }

        state->renderer = SDL_CreateRenderer(state->window, -1, SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);
        if (!state->renderer) 
        {
                fprintf(stderr, "SDL_CreateRenderer Error: %s\n", SDL_GetError());
                deinitialize_sdl(state);
                return 1;
        }

        state->texture = SDL_CreateTexture(state->renderer, SDL_PIXELFORMAT_RGB888, SDL_TEXTUREACCESS_STREAMING, WIDTH, HEIGHT);
        if (!state->texture) 
        {
                fprintf(stderr, "SDL_CreateTexture Error: %s\n", SDL_GetError());
                deinitialize_sdl(state);
                return 1;
        }

        state->pixels = (Uint32 *)calloc(WIDTH * HEIGHT, sizeof(Uint32));

        if (!state->pixels) 
        {
                fprintf(stderr, "Failed to allocate pixel buffer\n");
                deinitialize_sdl(state);
                return 1;
        }

        if (TTF_Init() != 0) {
                printf("Failed to initialize SDL_ttf: %s\n", TTF_GetError());
                deinitialize_sdl(state);
                return 1;
        }

        state->font = TTF_OpenFont(FPS_FONT, 24);
        if (!state->font) 
        {
                printf("Failed to load font: %s\n", TTF_GetError());
                deinitialize_sdl(state);
                return 1;
        }

        return 0;
}

Uint32 get_color(int iter)
{
        Uint8 r = 0, g = 0, b = 0;
        if (iter != MAX_ITER) 
        {
                double t = (double)iter / MAX_ITER;
                r = (Uint8)(9 * (1-t) * t * t * t * 255);
                g = (Uint8)(15 * (1-t) * (1-t) * t * t * 255);
                b = (Uint8)(8.5 * (1-t) * (1-t) * (1-t) * t * 255);
        }
        return (r << 16) | (g << 8) | b;
}

void render_mandelbrot(sdl_state_t* state, double x_offset, double y_offset, double zoom_factor)
{
        double complex original_min = -3.0 - 1.125 * I;
        double complex original_max =  0.0 + 1.125 * I;
        double complex center = (original_min + original_max) / 2.0;  // center = -1.5 + 0*I
        double complex offset = x_offset + y_offset * I;
        double complex min = (original_min - center) * zoom_factor + center + offset;
        double complex max = (original_max - center) * zoom_factor + center + offset;

        // double complex min = (-3.0 + x_offset) * zoom_factor + (-1.125 + y_offset) * I * zoom_factor;
        // double complex max = (0.0 + x_offset) * zoom_factor + (1.125 + y_offset) * I * zoom_factor;

        for (int py = 0; py < HEIGHT; py++) 
        {
                for (int px = 0; px < WIDTH; px++) 
                {
                        double complex point =  (creal(min) + (px / (double)WIDTH) * (creal(max) - creal(min))) +
                                                (cimag(min)+ (py / (double)HEIGHT) * (cimag(max) - cimag(min))) * I;

                        double complex z = 0 + 0 * I;

                        int iter = 0;
                        while ((cabs(z) <= 2.0) && iter < MAX_ITER)
                        {
                                z = z * z + point;
                                iter++;
                        }

                        state->pixels[py * WIDTH + px] = get_color(iter);
                }
        }

}

