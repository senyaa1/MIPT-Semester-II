cmake_minimum_required(VERSION 3.16)
project(hash_table LANGUAGES C ASM_NASM)

set(SOURCE_FILES
    src/main.c
    src/fs.c
    src/hash_table.c
    src/list.c
    src/crc32.s
)

add_executable(hash_table ${SOURCE_FILES})

set(CMAKE_ASM_NASM_OBJECT_FORMAT elf64)
set_source_files_properties(src/crc32.s PROPERTIES LANGUAGE ASM_NASM)

# define a variable that holds the "gcc + C-language" test
set(GCC_C_COND "$<AND:$<C_COMPILER_ID:GNU>,$<COMPILE_LANGUAGE:C>>")

if (CMAKE_BUILD_TYPE MATCHES "Debug")
    target_compile_options(hash_table PUBLIC
        # only when compiling C with GCC:
        $<${GCC_C_COND}:-g -march=native -fsanitize=address -fno-omit-frame-pointer -fpermissive -fno-inline-small-functions>
    )
    # link math library normally
    target_link_libraries(hash_table PUBLIC m)
    # link-options only when using GNU linker
    target_link_options(hash_table PUBLIC
        $<$<C_COMPILER_ID:GNU>:-g -fsanitize=address>
    )
endif()

if (CMAKE_BUILD_TYPE MATCHES "Release")
    target_compile_options(hash_table PUBLIC
        $<${GCC_C_COND}:-g -march=native -fpermissive -fno-omit-frame-pointer -fno-inline-small-functions>
    )
    target_link_options(hash_table PUBLIC
        $<$<C_COMPILER_ID:GNU>:-g -O3>
    )
endif()

