# scripts/build_native.ps1
param(
    [switch]$SkipAndroid,
    [switch]$SkipWindows
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

# Flutter Windows runner dirs
$winRunnerDebug  = Join-Path $projectRoot "build\windows\x64\runner\Debug"
$winRunnerRelease = Join-Path $projectRoot "build\windows\x64\runner\Release"

# Android targets & output
$androidArm64Target = "aarch64-linux-android"
$androidArmv7Target = "armv7-linux-androideabi"

$androidArm64SoName = "lib$rustLibName.so"
$androidArmv7SoName = "lib$rustLibName.so"

$androidArm64SoPath = Join-Path $nativeDir "target\$androidArm64Target\release\$androidArm64SoName"
$androidArmv7SoPath = Join-Path $nativeDir "target\$androidArmv7Target\release\$androidArmv7SoName"

# Flutter Android jniLibs dirs
$jniBase = Join-Path $projectRoot "android\app\src\main\jniLibs"
$jniArm64Dir = Join-Path $jniBase "arm64-v8a"
$jniArmv7Dir = Join-Path $jniBase "armeabi-v7a"

# 3. Go to native/ and clean
Write-Host "=== Cleaning Rust targets ===" -ForegroundColor Yellow
Set-Location $nativeDir
cargo clean

# 4. Build for Windows
if (-not $SkipWindows) {
    Write-Host "=== Building Rust library for Windows ($winTarget) ===" -ForegroundColor Yellow
    cargo build --release --target $winTarget

    if (-not (Test-Path $winDllPath)) {
        throw "Windows DLL not found at $winDllPath. Check build errors / target name."
    }

    # Ensure runner dirs exist
    New-Item -ItemType Directory -Force -Path $winRunnerDebug | Out-Null
    New-Item -ItemType Directory -Force -Path $winRunnerRelease | Out-Null

    Write-Host "Copying $winDllName to Windows runner folders..."
    Copy-Item $winDllPath $winRunnerDebug -Force
    Copy-Item $winDllPath $winRunnerRelease -Force

    Write-Host "Windows DLL copied to:"
    Write-Host "  $winRunnerDebug\$winDllName"
    Write-Host "  $winRunnerRelease\$winDllName"
} else {
    Write-Host "Skipping Windows build (SkipWindows flag set)" -ForegroundColor DarkYellow
}

# 5. Build for Android
if (-not $SkipAndroid) {
    Write-Host "=== Building Rust library for Android targets ===" -ForegroundColor Yellow

    # arm64-v8a
    Write-Host "-> Building for $androidArm64Target"
    cargo build --release --target $androidArm64Target

    if (-not (Test-Path $androidArm64SoPath)) {
        throw "Android arm64-v8a .so not found at $androidArm64SoPath. Check build errors / target name."
    }

    # armeabi-v7a
    Write-Host "-> Building for $androidArmv7Target"
    cargo build --release --target $androidArmv7Target

    if (-not (Test-Path $androidArmv7SoPath)) {
        throw "Android armeabi-v7a .so not found at $androidArmv7SoPath. Check build errors / target name."
    }

    # Ensure jniLibs dirs exist
    New-Item -ItemType Directory -Force -Path $jniArm64Dir | Out-Null
    New-Item -ItemType Directory -Force -Path $jniArmv7Dir | Out-Null

    Write-Host "Copying Android .so files to jniLibs..."
    Copy-Item $androidArm64SoPath $jniArm64Dir -Force
    Copy-Item $androidArmv7SoPath $jniArmv7Dir -Force

    Write-Host "Android SOs copied to:"
    Write-Host "  $jniArm64Dir\$androidArm64SoName"
    Write-Host "  $jniArmv7Dir\$androidArmv7SoName"
} else {
    Write-Host "Skipping Android build (SkipAndroid flag set)" -ForegroundColor DarkYellow
}

# 6. Done
Set-Location $projectRoot
Write-Host "=== Native build script completed successfully ===" -ForegroundColor Green
