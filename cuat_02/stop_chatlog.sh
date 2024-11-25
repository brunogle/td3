#!/bin/bash

# Set the module name and path
MODULE_NAME=chatlog_driver  # Replace with the name of your driver module (without .ko)
MODULE_PATH=/home/debian/td3/cuat_02/driver  # Replace with the folder path containing the .ko file
SERVER_PATH=/home/debian/td3/cuat_02/server  # Replace with the folder path where cmake needs to run

# Check if the module is already loaded
if lsmod | grep -q "$MODULE_NAME"; then
    echo "Module $MODULE_NAME is already loaded, unloading..."
    if sudo rmmod "$MODULE_PATH/$MODULE_NAME.ko"; then
       echo "Module $MODULE_NAME unloaded..." 
    else
        echo "Failed to unload $MODULE_NAME"
        exit 1
    fi
fi

pkill chatlog_server