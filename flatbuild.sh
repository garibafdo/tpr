flatpak run \
  --filesystem=$HOME \
  --share=network \
  --devel \
  --env=FLATPAK_ENABLE_SDK_EXT=llvm16 \
  --env=FLUTTER_ROOT=$HOME/flutter \
  --env=PATH=$HOME/flutter/bin:/usr/lib/sdk/llvm16/bin:$PATH \
  --env=CC=/usr/lib/sdk/llvm16/bin/clang \
  --env=CXX=/usr/lib/sdk/llvm16/bin/clang++ \
  --env=CMAKE_TOOLCHAIN_FILE=$HOME/git/tipitaka-pali-reader/clang_toolchain.cmake \
  --command=bash \
  org.freedesktop.Sdk//23.08 <<'EOF'

cd ~/git/tipitaka-pali-reader

# Clean old build cache (required for CMake to reconfigure)
rm -rf build/linux/x64/release

# Build with Flutter
flutter build linux --release

EOF
