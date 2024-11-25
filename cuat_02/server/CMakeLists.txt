cmake_minimum_required(VERSION 3.13)

project(chatlog_server) # Project name
set(EXECUTABLE_OUTPUT_PATH ${CMAKE_BINARY_DIR}\\bin) # Output path

#### COMPILER SETTINGS ####

set(CMAKE_CXX_STANDARD 20)
# Flags
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wextra -Wpedantic")
set(CMAKE_EXE_LINKER_FLAGS "")


#### EXECUTABLE ####

add_executable(chatlog_server)

target_include_directories(chatlog_server PRIVATE ${CMAKE_SOURCE_DIR}/lib ${CMAKE_SOURCE_DIR}/src)
target_link_libraries(chatlog_server rt pthread)

#### SOURCES #####

target_sources(chatlog_server
    PRIVATE 
        src/server.c
        src/buffer.c
        src/chatlog_server.c
        src/display.c

        lib/cJSON.c
)
