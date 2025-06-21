#!/bin/bash

export PATH=/usr/lib/sdk/llvm16/bin:$PATH
export CC=/usr/lib/sdk/llvm16/bin/clang
export CXX=/usr/lib/sdk/llvm16/bin/clang++

# Clean everything in the build directory
rm -rf build/linux/x64/release/*

# Run flutter build
flutter build linux --release
