#!/bin/bash
export PATH=/usr/lib/sdk/llvm16/bin:$PATH
export CC=/usr/lib/sdk/llvm16/bin/clang
export CXX=/usr/lib/sdk/llvm16/bin/clang++

# Step 1: Force CMake files to be generated
flutter build linux --release || true

# Step 2: Delete bad CMake cache
rm -f build/linux/x64/release/CMakeCache.txt

# Step 3: Re-run CMake with correct compilers
cd build/linux/x64/release/
cmake . -DCMAKE_C_COMPILER=$CC -DCMAKE_CXX_COMPILER=$CXX

# Step 4: Return and build again
cd ~/git/tipitaka-pali-reader
flutter build linux --release
