cmake_minimum_required(VERSION 3.25)

project(remote_lcd) # Project name
set(EXECUTABLE_OUTPUT_PATH ${CMAKE_BINARY_DIR}\\bin) # Output path

#### COMPILER SETTINGS ####

set(CMAKE_CXX_STANDARD 20)
# Flags
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wextra -Wpedantic")
set(CMAKE_EXE_LINKER_FLAGS "")


#### EXECUTABLE ####

add_executable(remote_lcd)

target_include_directories(remote_lcd PRIVATE ${CMAKE_SOURCE_DIR}/lib ${CMAKE_SOURCE_DIR}/src)


#### SOURCES #####

target_sources(remote_lcd
    PRIVATE 
        src/server.c
        src/buffer.c
        src/main.c
        src/handler.c

        lib/nxjson.c
)
