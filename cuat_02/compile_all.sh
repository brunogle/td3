#!/bin/bash

# Set the module name and path
MODULE_NAME=chatlog_driver  # Replace with the name of your driver module (without .ko)
MODULE_PATH=/home/debian/td3/cuat_02/driver  # Replace with the folder path containing the .ko file
SERVER_PATH=/home/debian/td3/cuat_02/server  # Replace with the folder path where cmake needs to run

# Check if the module is already loaded
if lsmod | grep -q "$MODULE_NAME"; then
    echo "Module $MODULE_NAME is already loaded, unloading..."
    if sudo rmmod "$MODULE_NAME.ko"; then
       echo "Module $MODULE_NAME unloaded..." 
    else
        echo "Failed to unload $MODULE_NAME"
        exit 1
    fi
fi


# Navigate to the module path and compile the module
if [ -d "$MODULE_PATH" ]; then
    cd "$MODULE_PATH" || { echo "Failed to access $MODULE_PATH"; exit 1; }
    echo "Running make in $MODULE_PATH..."

    if make; then
        echo "Compilation successful."
    else
        echo "Compilation failed. Check your Makefile and dependencies."
        exit 1
    fi

    # Check if the .ko file was generated
    if [ -f "$MODULE_PATH/$MODULE_NAME.ko" ]; then
        echo "Compiled module found: $MODULE_PATH/$MODULE_NAME.ko. Loading..."
        if sudo insmod "$MODULE_PATH/$MODULE_NAME.ko"; then
            echo "Module $MODULE_NAME loaded successfully."
        else
            echo "Failed to load $MODULE_NAME using insmod."
            exit 1
        fi
    else
        echo "Module $MODULE_NAME.ko not found after compilation."
        exit 1
    fi
else
    echo "Directory $MODULE_PATH does not exist."
    exit 1
fi


# Run cmake in the specified folder
if [ -d "$SERVER_PATH" ]; then
    cd "$SERVER_PATH"/build || { echo "Failed to access $SERVER_PATH"; exit 1; }
    echo "Running cmake in $SERVER_PATH..."
    
    if cmake ..; then
        echo "CMake configuration successful."
    else
        echo "CMake configuration failed. Check your CMakeLists.txt and dependencies."
        exit 1
    fi


    # Run make in the same folder
    echo "Running make in $CMAKE_PATH..."
    if make; then
        echo "Make completed successfully."
    else
        echo "Make failed. Check your build files and dependencies."
        exit 1
    fi
else
    echo "Directory $SERVER_PATH does not exist."
    exit 1
fi

cd "$(dirname "$0")"
