param(
    [switch]$SkipAndroid,
    [switch]$SkipWindows,
    [switch]$SkipClean
)

$ErrorActionPreference = "Stop"

Write-Host "=== Native build script starting ===" -ForegroundColor Cyan

# 1. Move to project root (parent of scripts/)
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
Set-Location $projectRoot
Write-Host "Project root: $projectRoot"

# 2. Paths and names
$nativeDir = Join-Path $projectRoot "native"
$rustLibName = "kivixa_native"  # Must match [lib].name in Cargo.toml

# Windows targets & output
$winTarget = "x86_64-pc-windows-msvc"
$winDllName = "$rustLibName.dll"
$winDllPath = Join-Path $nativeDir "target\$winTarget\release\$winDllName"

# Flutter Windows runner dirs (multiple locations for Flutter to find)
$winRunnerDebug  = Join-Path $projectRoot "build\windows\x64\runner\Debug"
$winRunnerRelease = Join-Path $projectRoot "build\windows\x64\runner\Release"
$winRunnerProfile = Join-Path $projectRoot "build\windows\x64\runner\Profile"
# rust_builder plugin directory (Flutter build picks up from here)
$rustBuilderWin = Join-Path $projectRoot "rust_builder\target\$winTarget\release"

# Android targets & output
$androidArm64Target = "aarch64-linux-android"
$androidArmv7Target = "armv7-linux-androideabi"

$androidArm64SoName = "lib$rustLibName.so"
$androidArmv7SoName = "lib$rustLibName.so"

$androidArm64SoPath = Join-Path $nativeDir "target\$androidArm64Target\release\$androidArm64SoName"
$androidArmv7SoPath = Join-Path $nativeDir "target\$androidArmv7Target\release\$androidArmv7SoName"

# Flutter Android jniLibs dirs (multiple locations)
$jniBase = Join-Path $projectRoot "android\app\src\main\jniLibs"
$jniArm64Dir = Join-Path $jniBase "arm64-v8a"
$jniArmv7Dir = Join-Path $jniBase "armeabi-v7a"
# rust_builder plugin jniLibs directory
$rustBuilderJniBase = Join-Path $projectRoot "rust_builder\android\src\main\jniLibs"
$rustBuilderJniArm64 = Join-Path $rustBuilderJniBase "arm64-v8a"
$rustBuilderJniArmv7 = Join-Path $rustBuilderJniBase "armeabi-v7a"

# 3. Go to native/ and optionally clean
if (-not $SkipClean) {
    Write-Host "=== Cleaning Rust targets ===" -ForegroundColor Yellow
    Set-Location $nativeDir
    cargo clean
} else {
    Write-Host "=== Skipping clean (SkipClean flag set) ===" -ForegroundColor DarkYellow
    Set-Location $nativeDir
}

# 4. Build for Windows
if (-not $SkipWindows) {
    Write-Host "=== Building Rust library for Windows ($winTarget) ===" -ForegroundColor Yellow
    $env:CMAKE_GENERATOR = "Ninja"
    $env:CMAKE_MAKE_PROGRAM = "ninja"
    cargo build --release --target $winTarget

    if (-not (Test-Path $winDllPath)) {
        throw "Windows DLL not found at $winDllPath. Check build errors / target name."
    }

    # Ensure all runner dirs exist
    New-Item -ItemType Directory -Force -Path $winRunnerDebug | Out-Null
    New-Item -ItemType Directory -Force -Path $winRunnerRelease | Out-Null
    New-Item -ItemType Directory -Force -Path $winRunnerProfile | Out-Null
    New-Item -ItemType Directory -Force -Path $rustBuilderWin | Out-Null

    Write-Host "Copying $winDllName to all Windows locations..."
    Copy-Item $winDllPath $winRunnerDebug -Force
    Copy-Item $winDllPath $winRunnerRelease -Force
    Copy-Item $winDllPath $winRunnerProfile -Force
    Copy-Item $winDllPath $rustBuilderWin -Force

    Write-Host "Windows DLL copied to:"
    Write-Host "  $winRunnerDebug\$winDllName"
    Write-Host "  $winRunnerRelease\$winDllName"
    Write-Host "  $winRunnerProfile\$winDllName"
    Write-Host "  $rustBuilderWin\$winDllName"
} else {
    Write-Host "Skipping Windows build (SkipWindows flag set)" -ForegroundColor DarkYellow
}

# 5. Build for Android
if (-not $SkipAndroid) {
    Write-Host "=== Building Rust library for Android targets ===" -ForegroundColor Yellow

    # Detect NDK path
    $ndkPath = $env:ANDROID_NDK_HOME
    if (-not $ndkPath) {
        $ndkPath = $env:NDK_HOME
    }
    if (-not $ndkPath) {
        # Try common locations
        $sdkPath = $env:ANDROID_SDK_ROOT
        if (-not $sdkPath) {
            $sdkPath = "$env:LOCALAPPDATA\Android\Sdk"
        }
        # Find latest NDK version
        $ndkDir = Join-Path $sdkPath "ndk"
        if (Test-Path $ndkDir) {
            $latestNdk = Get-ChildItem $ndkDir -Directory | Sort-Object Name -Descending | Select-Object -First 1
            if ($latestNdk) {
                $ndkPath = $latestNdk.FullName
            }
        }
    }

    if (-not $ndkPath -or -not (Test-Path $ndkPath)) {
        throw "Android NDK not found. Set ANDROID_NDK_HOME environment variable."
    }
    Write-Host "Using Android NDK: $ndkPath"

    # Set up toolchain paths for NDK r25+
    $toolchainDir = Join-Path $ndkPath "toolchains\llvm\prebuilt\windows-x86_64"
    $binDir = Join-Path $toolchainDir "bin"
    
    # API level (minimum 23 for most features)
    $apiLevel = 23

    # Set environment for cross-compilation
    # IMPORTANT: Add NDK bin to PATH and set ANDROID_NDK for build.rs to find toolchain
    $env:PATH = "$binDir;$env:PATH"
    $env:ANDROID_NDK = $ndkPath
    $env:ANDROID_NDK_ROOT = $ndkPath
    $env:ANDROID_PLATFORM = "android-$apiLevel"
    
    # Clear any conflicting CLANG_PATH that might interfere
    $env:CLANG_PATH = $null

    # arm64-v8a
    Write-Host "-> Building for $androidArm64Target"
    $env:CC_aarch64_linux_android = Join-Path $binDir "aarch64-linux-android$apiLevel-clang.cmd"
    $env:AR_aarch64_linux_android = Join-Path $binDir "llvm-ar.exe"
    $env:CARGO_TARGET_AARCH64_LINUX_ANDROID_LINKER = Join-Path $binDir "aarch64-linux-android$apiLevel-clang.cmd"
    # Note: We do NOT set CFLAGS here - the CMake Android toolchain file handles sysroot configuration
    cargo build --release --target $androidArm64Target

    if (-not (Test-Path $androidArm64SoPath)) {
        throw "Android arm64-v8a .so not found at $androidArm64SoPath. Check build errors / target name."
    }

    # armeabi-v7a
    Write-Host "-> Building for $androidArmv7Target"
    $env:CC_armv7_linux_androideabi = Join-Path $binDir "armv7a-linux-androideabi$apiLevel-clang.cmd"
    $env:AR_armv7_linux_androideabi = Join-Path $binDir "llvm-ar.exe"
    $env:CARGO_TARGET_ARMV7_LINUX_ANDROIDEABI_LINKER = Join-Path $binDir "armv7a-linux-androideabi$apiLevel-clang.cmd"
    # Note: We do NOT set CFLAGS here - the CMake Android toolchain file handles sysroot configuration
    cargo build --release --target $androidArmv7Target

    if (-not (Test-Path $androidArmv7SoPath)) {
        throw "Android armeabi-v7a .so not found at $androidArmv7SoPath. Check build errors / target name."
    }

    # Ensure all jniLibs dirs exist
    New-Item -ItemType Directory -Force -Path $jniArm64Dir | Out-Null
    New-Item -ItemType Directory -Force -Path $jniArmv7Dir | Out-Null
    New-Item -ItemType Directory -Force -Path $rustBuilderJniArm64 | Out-Null
    New-Item -ItemType Directory -Force -Path $rustBuilderJniArmv7 | Out-Null

    Write-Host "Copying Android .so files to all jniLibs locations..."
    # Main app jniLibs
    Copy-Item $androidArm64SoPath $jniArm64Dir -Force
    Copy-Item $androidArmv7SoPath $jniArmv7Dir -Force
    # rust_builder plugin jniLibs
    Copy-Item $androidArm64SoPath $rustBuilderJniArm64 -Force
    Copy-Item $androidArmv7SoPath $rustBuilderJniArmv7 -Force

    Write-Host "Android SOs copied to:"
    Write-Host "  $jniArm64Dir\$androidArm64SoName"
    Write-Host "  $jniArmv7Dir\$androidArmv7SoName"
    Write-Host "  $rustBuilderJniArm64\$androidArm64SoName"
    Write-Host "  $rustBuilderJniArmv7\$androidArmv7SoName"
} else {
    Write-Host "Skipping Android build (SkipAndroid flag set)" -ForegroundColor DarkYellow
}

# 6. Done
Set-Location $projectRoot
Write-Host "=== Native build script completed successfully ===" -ForegroundColor Green
