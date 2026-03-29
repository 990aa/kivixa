#!/bin/bash
set -e

# 1. Setup Environment
NDK_BIN="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin"
API_LEVEL=23

# 2. Export Rust Cross-Compilation Variables
export CC_aarch64_linux_android="${NDK_BIN}/aarch64-linux-android${API_LEVEL}-clang"
export AR_aarch64_linux_android="${NDK_BIN}/llvm-ar"
export CARGO_TARGET_AARCH64_LINUX_ANDROID_LINKER="${NDK_BIN}/aarch64-linux-android${API_LEVEL}-clang"

export CC_armv7_linux_androideabi="${NDK_BIN}/armv7a-linux-androideabi${API_LEVEL}-clang"
export AR_armv7_linux_androideabi="${NDK_BIN}/llvm-ar"
export CARGO_TARGET_ARMV7_LINUX_ANDROIDEABI_LINKER="${NDK_BIN}/armv7a-linux-androideabi${API_LEVEL}-clang"

export CC_x86_64_linux_android="${NDK_BIN}/x86_64-linux-android${API_LEVEL}-clang"
export AR_x86_64_linux_android="${NDK_BIN}/llvm-ar"
export CARGO_TARGET_X86_64_LINUX_ANDROID_LINKER="${NDK_BIN}/x86_64-linux-android${API_LEVEL}-clang"

# 3. Build Rust Libraries
for dir in native native_math; do
    cd $dir
    cargo build --release --target aarch64-linux-android
    cargo build --release --target armv7-linux-androideabi
    cargo build --release --target x86_64-linux-android
    cd ..
done

# 4. Organize jniLibs
libs=("arm64-v8a" "armeabi-v7a" "x86_64")
targets=("aarch64-linux-android" "armv7-linux-androideabi" "x86_64-linux-android")

for i in "${!libs[@]}"; do
    mkdir -p android/app/src/main/jniLibs/${libs[$i]}
    mkdir -p rust_builder/android/src/main/jniLibs/${libs[$i]}
    
    cp native/target/${targets[$i]}/release/libkivixa_native.so android/app/src/main/jniLibs/${libs[$i]}/
    cp native/target/${targets[$i]}/release/libkivixa_native.so rust_builder/android/src/main/jniLibs/${libs[$i]}/
    
    cp native_math/target/${targets[$i]}/release/libkivixa_math.so android/app/src/main/jniLibs/${libs[$i]}/
    cp native_math/target/${targets[$i]}/release/libkivixa_math.so rust_builder/android/src/main/jniLibs/${libs[$i]}/
done

echo "Native build complete!"