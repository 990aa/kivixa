# Kivixa Native Rust Library Implementation

This document describes the Rust native library used by Kivixa for AI/LLM capabilities.

## Overview

Kivixa uses a native Rust library (`kivixa_native`) for on-device AI inference via llama.cpp. The library is integrated using Flutter Rust Bridge and compiled separately for each target platform.

## Directory Structure

```
native/
├── Cargo.toml          # Main Rust library config
├── src/
│   └── api.rs          # Flutter Rust Bridge API
├── vendor/
│   └── llama-cpp-sys-2/  # Patched llama.cpp bindings
└── .cargo/
    └── config.toml     # Target-specific build config

rust_builder/           # Flutter Rust Bridge integration
android/app/src/main/jniLibs/
├── arm64-v8a/libkivixa_native.so
└── armeabi-v7a/libkivixa_native.so

build/windows/x64/runner/
├── Debug/kivixa_native.dll
└── Release/kivixa_native.dll
```

## Platform-Specific Build Strategies

### Windows Build

**Toolchain**: MSVC (Visual Studio Build Tools)

**Process**:
1. Run `scripts/build_native.ps1`
2. Cargo builds for `x86_64-pc-windows-msvc` target
3. llama.cpp compiled via CMake with Ninja generator
4. Output: `kivixa_native.dll` copied to Flutter runner directories

**GPU Support**: CPU-only with AVX2 auto-detection. No SDK required.

### Android Build

**Toolchain**: Android NDK (r25+) with CMake toolchain file

**Process**:
1. Run `scripts/build_native.ps1` (without `-SkipAndroid`)
2. Script auto-detects NDK from environment variables
3. Builds for two targets:
   - `aarch64-linux-android` (arm64-v8a)
   - `armv7-linux-androideabi` (armeabi-v7a)
4. Output: `.so` files copied to `jniLibs/` directories

**Key Environment Variables**:
- `ANDROID_NDK` / `ANDROID_NDK_ROOT` - NDK path
- `ANDROID_PLATFORM` - API level (default: android-23)

## Cross-Compilation Patches

The vendor `llama-cpp-sys-2/build.rs` includes patches for Windows→Android cross-compilation:

1. **CMAKE_C/CXX_FLAGS**: Explicit `--target=<arch>-linux-android<api>` with API level suffix
2. **extract_lib_names()**: Uses target_os instead of `cfg!` macros for correct `.a`/`.lib` detection
3. **CARGO_CFG_TARGET_FEATURE**: Made optional (may not be set for Android targets)

## Build Commands

```powershell
# Windows only (fast)
scripts/build_native.ps1 -SkipAndroid

# Android only
scripts/build_native.ps1 -SkipWindows

# Both platforms
scripts/build_native.ps1
```

## Dependencies

- **Rust 1.70+** with targets:
  - `x86_64-pc-windows-msvc`
  - `aarch64-linux-android`
  - `armv7-linux-androideabi`
- **Android NDK r25+**
- **CMake 3.20+** with Ninja
- **Visual Studio Build Tools** (Windows)

## Troubleshooting

### DLL Not Found (Windows)
Run `scripts/build_native.ps1 -SkipAndroid` to build the Windows DLL.

### Android Build Fails
1. Ensure NDK is installed: `sdkmanager "ndk;29.0.14206865"`
2. Set `ANDROID_NDK_HOME` environment variable
3. Verify Rust targets: `rustup target add aarch64-linux-android armv7-linux-androideabi`
