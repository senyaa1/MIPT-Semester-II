cmake_minimum_required(VERSION 3.16)
project(hash_table LANGUAGES C ASM_NASM)

set(SOURCE_FILES
	src/main.c
	src/fs.c
	src/hash_table.c
)

add_executable(hash_table ${SOURCE_FILES})

if (CMAKE_BUILD_TYPE MATCHES "Debug")
    target_compile_options(hash_table PUBLIC -g -fsanitize=address -fno-omit-frame-pointer -fpermissive -fno-inline-small-functions)
    target_link_options(hash_table PUBLIC -g -fsanitize=address -lm)
endif()

if (CMAKE_BUILD_TYPE MATCHES "Release")
    target_compile_options(hash_table PUBLIC -g -O3 -march=native -flto -fpermissive -fno-omit-frame-pointer -fno-inline-small-functions)
    target_link_options(hash_table PUBLIC -g -O3 -flto)
endif()

