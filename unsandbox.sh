#!/bin/bash

# Unset sandbox-specific environment variables
unset CC
unset CXX
unset CMAKE_TOOLCHAIN_FILE

# Clean CMake cache and build folder
echo "Cleaning old CMake cache..."
rm -f build/linux/x64/release/CMakeCache.txt
rm -rf build/linux/x64/release/CMakeFiles

echo "Reset complete. You can now build with:"
echo "flutter build linux --release"
