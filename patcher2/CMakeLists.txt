cmake_minimum_required(VERSION 3.16)

project(patcher VERSION 1.0.0 LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(SKIP_AUTOMOC ON)


find_package(Qt6 REQUIRED COMPONENTS Core Gui UiTools Widgets)
qt_standard_project_setup()

qt_add_executable(patcher
    src/main.cpp
    src/fs.cpp
    src/gfx.cpp
    src/music.c
    src/fs.c
    src/patcher.c
)

target_link_libraries(patcher PUBLIC
    Qt::Core
    Qt::Gui
    Qt::UiTools
    Qt::Widgets
    -lmikmod
    -lpthread
)
