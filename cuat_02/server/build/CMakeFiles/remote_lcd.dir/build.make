# CMAKE generated file: DO NOT EDIT!
# Generated by "Unix Makefiles" Generator, CMake Version 3.13

# Delete rule output on recipe failure.
.DELETE_ON_ERROR:


#=============================================================================
# Special targets provided by cmake.

# Disable implicit rules so canonical targets will work.
.SUFFIXES:


# Remove some rules from gmake that .SUFFIXES does not remove.
SUFFIXES =

.SUFFIXES: .hpux_make_needs_suffix_list


# Suppress display of executed commands.
$(VERBOSE).SILENT:


# A target that is always out of date.
cmake_force:

.PHONY : cmake_force

#=============================================================================
# Set environment variables for the build.

# The shell in which to execute make rules.
SHELL = /bin/sh

# The CMake executable.
CMAKE_COMMAND = /usr/bin/cmake

# The command to remove a file.
RM = /usr/bin/cmake -E remove -f

# Escaping for special characters.
EQUALS = =

# The top-level source directory on which CMake was run.
CMAKE_SOURCE_DIR = /home/debian/td3/cuat_02/server

# The top-level build directory on which CMake was run.
CMAKE_BINARY_DIR = /home/debian/td3/cuat_02/server/build

# Include any dependencies generated for this target.
include CMakeFiles/remote_lcd.dir/depend.make

# Include the progress variables for this target.
include CMakeFiles/remote_lcd.dir/progress.make

# Include the compile flags for this target's objects.
include CMakeFiles/remote_lcd.dir/flags.make

CMakeFiles/remote_lcd.dir/src/server.c.o: CMakeFiles/remote_lcd.dir/flags.make
CMakeFiles/remote_lcd.dir/src/server.c.o: ../src/server.c
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/home/debian/td3/cuat_02/server/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_1) "Building C object CMakeFiles/remote_lcd.dir/src/server.c.o"
	/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -o CMakeFiles/remote_lcd.dir/src/server.c.o   -c /home/debian/td3/cuat_02/server/src/server.c

CMakeFiles/remote_lcd.dir/src/server.c.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing C source to CMakeFiles/remote_lcd.dir/src/server.c.i"
	/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -E /home/debian/td3/cuat_02/server/src/server.c > CMakeFiles/remote_lcd.dir/src/server.c.i

CMakeFiles/remote_lcd.dir/src/server.c.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling C source to assembly CMakeFiles/remote_lcd.dir/src/server.c.s"
	/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -S /home/debian/td3/cuat_02/server/src/server.c -o CMakeFiles/remote_lcd.dir/src/server.c.s

CMakeFiles/remote_lcd.dir/src/buffer.c.o: CMakeFiles/remote_lcd.dir/flags.make
CMakeFiles/remote_lcd.dir/src/buffer.c.o: ../src/buffer.c
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/home/debian/td3/cuat_02/server/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_2) "Building C object CMakeFiles/remote_lcd.dir/src/buffer.c.o"
	/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -o CMakeFiles/remote_lcd.dir/src/buffer.c.o   -c /home/debian/td3/cuat_02/server/src/buffer.c

CMakeFiles/remote_lcd.dir/src/buffer.c.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing C source to CMakeFiles/remote_lcd.dir/src/buffer.c.i"
	/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -E /home/debian/td3/cuat_02/server/src/buffer.c > CMakeFiles/remote_lcd.dir/src/buffer.c.i

CMakeFiles/remote_lcd.dir/src/buffer.c.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling C source to assembly CMakeFiles/remote_lcd.dir/src/buffer.c.s"
	/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -S /home/debian/td3/cuat_02/server/src/buffer.c -o CMakeFiles/remote_lcd.dir/src/buffer.c.s

CMakeFiles/remote_lcd.dir/src/main.c.o: CMakeFiles/remote_lcd.dir/flags.make
CMakeFiles/remote_lcd.dir/src/main.c.o: ../src/main.c
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/home/debian/td3/cuat_02/server/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_3) "Building C object CMakeFiles/remote_lcd.dir/src/main.c.o"
	/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -o CMakeFiles/remote_lcd.dir/src/main.c.o   -c /home/debian/td3/cuat_02/server/src/main.c

CMakeFiles/remote_lcd.dir/src/main.c.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing C source to CMakeFiles/remote_lcd.dir/src/main.c.i"
	/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -E /home/debian/td3/cuat_02/server/src/main.c > CMakeFiles/remote_lcd.dir/src/main.c.i

CMakeFiles/remote_lcd.dir/src/main.c.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling C source to assembly CMakeFiles/remote_lcd.dir/src/main.c.s"
	/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -S /home/debian/td3/cuat_02/server/src/main.c -o CMakeFiles/remote_lcd.dir/src/main.c.s

CMakeFiles/remote_lcd.dir/src/handler.c.o: CMakeFiles/remote_lcd.dir/flags.make
CMakeFiles/remote_lcd.dir/src/handler.c.o: ../src/handler.c
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/home/debian/td3/cuat_02/server/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_4) "Building C object CMakeFiles/remote_lcd.dir/src/handler.c.o"
	/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -o CMakeFiles/remote_lcd.dir/src/handler.c.o   -c /home/debian/td3/cuat_02/server/src/handler.c

CMakeFiles/remote_lcd.dir/src/handler.c.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing C source to CMakeFiles/remote_lcd.dir/src/handler.c.i"
	/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -E /home/debian/td3/cuat_02/server/src/handler.c > CMakeFiles/remote_lcd.dir/src/handler.c.i

CMakeFiles/remote_lcd.dir/src/handler.c.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling C source to assembly CMakeFiles/remote_lcd.dir/src/handler.c.s"
	/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -S /home/debian/td3/cuat_02/server/src/handler.c -o CMakeFiles/remote_lcd.dir/src/handler.c.s

CMakeFiles/remote_lcd.dir/lib/nxjson.c.o: CMakeFiles/remote_lcd.dir/flags.make
CMakeFiles/remote_lcd.dir/lib/nxjson.c.o: ../lib/nxjson.c
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/home/debian/td3/cuat_02/server/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_5) "Building C object CMakeFiles/remote_lcd.dir/lib/nxjson.c.o"
	/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -o CMakeFiles/remote_lcd.dir/lib/nxjson.c.o   -c /home/debian/td3/cuat_02/server/lib/nxjson.c

CMakeFiles/remote_lcd.dir/lib/nxjson.c.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing C source to CMakeFiles/remote_lcd.dir/lib/nxjson.c.i"
	/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -E /home/debian/td3/cuat_02/server/lib/nxjson.c > CMakeFiles/remote_lcd.dir/lib/nxjson.c.i

CMakeFiles/remote_lcd.dir/lib/nxjson.c.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling C source to assembly CMakeFiles/remote_lcd.dir/lib/nxjson.c.s"
	/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -S /home/debian/td3/cuat_02/server/lib/nxjson.c -o CMakeFiles/remote_lcd.dir/lib/nxjson.c.s

CMakeFiles/remote_lcd.dir/lib/cJSON.c.o: CMakeFiles/remote_lcd.dir/flags.make
CMakeFiles/remote_lcd.dir/lib/cJSON.c.o: ../lib/cJSON.c
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/home/debian/td3/cuat_02/server/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_6) "Building C object CMakeFiles/remote_lcd.dir/lib/cJSON.c.o"
	/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -o CMakeFiles/remote_lcd.dir/lib/cJSON.c.o   -c /home/debian/td3/cuat_02/server/lib/cJSON.c

CMakeFiles/remote_lcd.dir/lib/cJSON.c.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing C source to CMakeFiles/remote_lcd.dir/lib/cJSON.c.i"
	/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -E /home/debian/td3/cuat_02/server/lib/cJSON.c > CMakeFiles/remote_lcd.dir/lib/cJSON.c.i

CMakeFiles/remote_lcd.dir/lib/cJSON.c.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling C source to assembly CMakeFiles/remote_lcd.dir/lib/cJSON.c.s"
	/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -S /home/debian/td3/cuat_02/server/lib/cJSON.c -o CMakeFiles/remote_lcd.dir/lib/cJSON.c.s

# Object files for target remote_lcd
remote_lcd_OBJECTS = \
"CMakeFiles/remote_lcd.dir/src/server.c.o" \
"CMakeFiles/remote_lcd.dir/src/buffer.c.o" \
"CMakeFiles/remote_lcd.dir/src/main.c.o" \
"CMakeFiles/remote_lcd.dir/src/handler.c.o" \
"CMakeFiles/remote_lcd.dir/lib/nxjson.c.o" \
"CMakeFiles/remote_lcd.dir/lib/cJSON.c.o"

# External object files for target remote_lcd
remote_lcd_EXTERNAL_OBJECTS =

bin/remote_lcd: CMakeFiles/remote_lcd.dir/src/server.c.o
bin/remote_lcd: CMakeFiles/remote_lcd.dir/src/buffer.c.o
bin/remote_lcd: CMakeFiles/remote_lcd.dir/src/main.c.o
bin/remote_lcd: CMakeFiles/remote_lcd.dir/src/handler.c.o
bin/remote_lcd: CMakeFiles/remote_lcd.dir/lib/nxjson.c.o
bin/remote_lcd: CMakeFiles/remote_lcd.dir/lib/cJSON.c.o
bin/remote_lcd: CMakeFiles/remote_lcd.dir/build.make
bin/remote_lcd: CMakeFiles/remote_lcd.dir/link.txt
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --bold --progress-dir=/home/debian/td3/cuat_02/server/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_7) "Linking C executable bin/remote_lcd"
	$(CMAKE_COMMAND) -E cmake_link_script CMakeFiles/remote_lcd.dir/link.txt --verbose=$(VERBOSE)

# Rule to build all files generated by this target.
CMakeFiles/remote_lcd.dir/build: bin/remote_lcd

.PHONY : CMakeFiles/remote_lcd.dir/build

CMakeFiles/remote_lcd.dir/clean:
	$(CMAKE_COMMAND) -P CMakeFiles/remote_lcd.dir/cmake_clean.cmake
.PHONY : CMakeFiles/remote_lcd.dir/clean

CMakeFiles/remote_lcd.dir/depend:
	cd /home/debian/td3/cuat_02/server/build && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /home/debian/td3/cuat_02/server /home/debian/td3/cuat_02/server /home/debian/td3/cuat_02/server/build /home/debian/td3/cuat_02/server/build /home/debian/td3/cuat_02/server/build/CMakeFiles/remote_lcd.dir/DependInfo.cmake --color=$(COLOR)
.PHONY : CMakeFiles/remote_lcd.dir/depend

