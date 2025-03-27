cmake_minimum_required(VERSION 3.16)
project(mandelbrot LANGUAGES C)

set(CMAKE_C_STANDARD 99)

find_package(SDL2 REQUIRED)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/$<CONFIGURATION>")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/$<CONFIGURATION>")

set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -Ofast")

set(SOURCE_FILES
    src/main.c
    src/graphics.c
    src/fps.c
)


add_executable(mandelbrot ${SOURCE_FILES})
target_link_libraries(mandelbrot PRIVATE SDL2::SDL2 SDL2_ttf m)

