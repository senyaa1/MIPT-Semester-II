#include <SDL2/SDL.h>
#include <SDL2/SDL_stdinc.h>
#include <SDL2/SDL_ttf.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <complex.h>
#include <immintrin.h>

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

static Uint32 color_cache[MAX_ITER] = { 0 };

Uint32 get_color(int iter)
{
        if (iter == MAX_ITER)
                return 0;

        double t = (double)iter / MAX_ITER;
        double freq = 10.0 + 5.0 * t; 

        Uint8 r = (Uint8)(127.5 * (1 + sin(freq * t + 0.0)));
        Uint8 g = (Uint8)(127.5 * (1 + sin(freq * t + 2.094)));
        Uint8 b = (Uint8)(127.5 * (1 + sin(freq * t + 4.188)));

        return (r << 16) | (g << 8) | b;
}

static void color_precompute()
{
        for(int i = 0; i < MAX_ITER; i++)
                color_cache[i] = get_color(i);
}


void render_mandelbrot_default(sdl_state_t* state, float x_offset, float y_offset, float zoom_factor)
{
        float complex original_min = -3.0 - 1.125 * I;
        float complex original_max =  0.0 + 1.125 * I;
        float complex center = (original_min + original_max) / 2.0;  // center = -1.5 + 0*I
        float complex offset = x_offset + y_offset * I;
        float complex min = (original_min - center) * zoom_factor + center + offset;
        float complex max = (original_max - center) * zoom_factor + center + offset;

        for (int py = 0; py < HEIGHT; py++) 
        {
                for (int px = 0; px < WIDTH; px++) 
                {
                        float complex point =  (creal(min) + (px / (float)WIDTH) * (creal(max) - creal(min))) +
                                                (cimag(min)+ (py / (float)HEIGHT) * (cimag(max) - cimag(min))) * I;

                        float complex z = 0 + 0 * I;

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

void render_mandelbrot_parallelized(sdl_state_t* state, float x_offset, float y_offset, float zoom_factor)
{
        const float original_min_real = -3.0f, original_min_imag = -1.125f;
        const float original_max_real =  0.0f, original_max_imag =  1.125f;

        float center_real = (original_min_real + original_max_real) * 0.5f;
        float center_imag = (original_min_imag + original_max_imag) * 0.5f;

        float min_real = (original_min_real - center_real) * zoom_factor + center_real + x_offset;
        float min_imag = (original_min_imag - center_imag) * zoom_factor + center_imag + y_offset;
        float max_real = (original_max_real - center_real) * zoom_factor + center_real + x_offset;
        float max_imag = (original_max_imag - center_imag) * zoom_factor + center_imag + y_offset;

        float real_factor = (max_real - min_real) / WIDTH;
        float imag_factor = (max_imag - min_imag) / HEIGHT;

        float offset[8] = { 0.0f, 1.0f, 2.0f, 3.0f, 4.0f, 5.0f, 6.0f, 7.0f };

        color_precompute();

        for (int py = 0; py < HEIGHT; py++) 
        {
                float c_imag = min_imag + py * imag_factor;

                for (int px = 0; px < WIDTH; px += 8) 
                {
                        float base_real = min_real + px * real_factor;

                        float c_real[8] = {};
                        float z_real[8] = {};
                        float z_imag[8] = {};
                        int iter[8] =  {};

                        for (int i = 0; i < 8; i++) 
                                c_real[i] = base_real + offset[i] * real_factor;

                        for (int iter_idx = 0; iter_idx < MAX_ITER; iter_idx++) 
                        {
                                float new_z_real[8] = {};
                                float new_z_imag[8] = {};

                                for (int i = 0; i < 8; i++) 
                                {
                                        float zr2 = z_real[i] * z_real[i];
                                        float zi2 = z_imag[i] * z_imag[i];
                                        float mag2 = zr2 + zi2;

                                        if (mag2 <= 4.0f)
                                        {
                                                new_z_real[i] = zr2 - zi2 + c_real[i];
                                                new_z_imag[i] = 2.0f * z_real[i] * z_imag[i] + c_imag;
                                                iter[i]++;
                                        }
                                        else
                                        {
                                                new_z_real[i] = z_real[i];
                                                new_z_imag[i] = z_imag[i];
                                        }
                                }

                                for (int i = 0; i < 8; i++) 
                                {
                                        z_real[i] = new_z_real[i];
                                        z_imag[i] = new_z_imag[i];
                                }
                        }

                        for (int i = 0; i < 8; i++) 
                        {
                                int pixel_index = py * WIDTH + px + i;
                                state->pixels[pixel_index] = color_cache[iter[i]];
                        }
                }
        }
}



void render_mandelbrot_intrinsics(sdl_state_t* state, float x_offset, float y_offset, float zoom_factor)
{
        const float original_min_real = -3.0f, original_min_imag = -1.125f;
        const float original_max_real =  0.0f, original_max_imag =  1.125f;

        float center_real = (original_min_real + original_max_real) / 2.0f;
        float center_imag = (original_min_imag + original_max_imag) / 2.0f;

        float min_real = (original_min_real - center_real) * zoom_factor + center_real + x_offset;
        float min_imag = (original_min_imag - center_imag) * zoom_factor + center_imag + y_offset;
        float max_real = (original_max_real - center_real) * zoom_factor + center_real + x_offset;
        float max_imag = (original_max_imag - center_imag) * zoom_factor + center_imag + y_offset;

        float real_factor = (max_real - min_real) / WIDTH;
        float imag_factor = (max_imag - min_imag) / HEIGHT;

        __m256 offsetVec = _mm256_set_ps(7.0f, 6.0f, 5.0f, 4.0f, 3.0f, 2.0f, 1.0f, 0.0f);

        color_precompute();

        for (int py = 0; py < HEIGHT; py++) 
        {
                float c_imag_val = min_imag + py * imag_factor;
                __m256 c_imag = _mm256_set1_ps(c_imag_val);

                for (int px = 0; px < WIDTH; px += 8) 
                {
                        float base_real = min_real + px * real_factor;
                        __m256 base_real_vec = _mm256_set1_ps(base_real);
                        __m256 real_factor_vec = _mm256_set1_ps(real_factor);

                        __m256 c_real = _mm256_fmadd_ps(offsetVec, real_factor_vec, base_real_vec);

                        __m256 z_real = _mm256_setzero_ps();
                        __m256 z_imag = _mm256_setzero_ps();
                        __m256i iter = _mm256_setzero_si256();

                        for (int i = 0; i < MAX_ITER; i++) 
                        {
                                __m256 zr2 = _mm256_mul_ps(z_real, z_real);
                                __m256 zi2 = _mm256_mul_ps(z_imag, z_imag);
                                __m256 mag2 = _mm256_add_ps(zr2, zi2);

                                __m256 cmp = _mm256_cmp_ps(mag2, _mm256_set1_ps(4.0f), _CMP_LE_OQ);

                                if (!_mm256_movemask_ps(cmp))
                                        break;

                                __m256i cmp_i = _mm256_castps_si256(cmp);
                                __m256i one = _mm256_set1_epi32(1);
                                __m256i iter_inc = _mm256_and_si256(one, cmp_i);
                                iter = _mm256_add_epi32(iter, iter_inc);

                                // new_z_real = z_real^2 - z_imag^2 + c_real.
                                __m256 new_z_real = _mm256_add_ps(_mm256_sub_ps(zr2, zi2), c_real);
                                // new_z_imag = 2 * z_real * z_imag + c_imag.
                                __m256 new_z_imag = _mm256_add_ps(_mm256_mul_ps(_mm256_set1_ps(2.0f),
                                                                                _mm256_mul_ps(z_real, z_imag)),
                                                                  c_imag);

                                z_real = _mm256_blendv_ps(z_real, new_z_real, cmp);
                                z_imag = _mm256_blendv_ps(z_imag, new_z_imag, cmp);
                        }


                        int iter_arr[8]  __attribute__((aligned(16))) = { 0 };
                        _mm256_store_si256((__m256i*)iter_arr, iter);

                        for (int i = 0; i < 8; i++) 
                        {
                                int col = px + i;
                                if (col >= WIDTH)
                                        continue;

                                int pixel_index = py * WIDTH + col;
                                state->pixels[pixel_index] = color_cache[iter_arr[i]];
                        }
                }
        }
}
