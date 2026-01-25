# build_math.ps1
# Build script for the kivixa_math native library
# Isolated from the main AI inference native module
# Always runs: Clean + Generate Bindings + Release Build + Copy

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$MathRoot = Join-Path $ProjectRoot "native_math"
$TargetDir = Join-Path $MathRoot "target"

# Library names
$LibName = "kivixa_math"
$WinDllName = "$LibName.dll"
$LinuxSoName = "lib$LibName.so"
$MacDylibName = "lib$LibName.dylib"

# Destination directories for Windows
$WinRunnerDebug = Join-Path $ProjectRoot "build/windows/x64/runner/Debug"
$WinRunnerRelease = Join-Path $ProjectRoot "build/windows/x64/runner/Release"

# Destination directories for jniLibs (Android)
$JniBase = Join-Path $ProjectRoot "android/app/src/main/jniLibs"
$JniArm64Dir = Join-Path $JniBase "arm64-v8a"
$JniArmv7Dir = Join-Path $JniBase "armeabi-v7a"

function Write-Header {
    param([string]$Message)
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host $Message -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan
}

function Write-Step {
    param([string]$Message)
    Write-Host ">> $Message" -ForegroundColor Yellow
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

# Step 1: Clean build artifacts
Write-Header "Step 1: Cleaning build artifacts"

if (Test-Path $TargetDir) {
    Write-Step "Removing target directory..."
    Remove-Item -Recurse -Force $TargetDir
}

$DartOutput = Join-Path $ProjectRoot "lib/src/rust_math"
if (Test-Path $DartOutput) {
    Write-Step "Removing generated Dart files..."
    Remove-Item -Recurse -Force $DartOutput
}

Write-Success "Clean completed"

# Step 2: Generate Flutter Rust Bridge bindings
Write-Header "Step 2: Generating Flutter Rust Bridge bindings"

Push-Location $ProjectRoot
try {
    Write-Step "Running flutter_rust_bridge_codegen..."
    flutter_rust_bridge_codegen generate --config-file flutter_rust_bridge_math.yaml
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to generate bindings"
        Write-Host "Note: Binding generation may fail if flutter_rust_bridge_codegen is not installed or config is invalid." -ForegroundColor Yellow
        Write-Host "Continuing with build..." -ForegroundColor Yellow
    }
    else {
        Write-Success "Bindings generated successfully"
    }
}
finally {
    Pop-Location
}

# Step 3: Build the Rust library in release mode
Write-Header "Step 3: Building kivixa_math library (Release)"

Push-Location $MathRoot
try {
    Write-Step "Building in release mode..."
    cargo build --release
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Build failed"
        exit 1
    }
    
    Write-Success "Build completed successfully"
    
    $OutputPath = Join-Path $TargetDir "release"
    Write-Host "`nOutput location: $OutputPath" -ForegroundColor Gray
    
    Write-Step "Built artifacts:"
    Get-ChildItem -Path $OutputPath -Filter "*.dll" -ErrorAction SilentlyContinue | ForEach-Object { Write-Host "  - $($_.Name)" }
    Get-ChildItem -Path $OutputPath -Filter "*.so" -ErrorAction SilentlyContinue | ForEach-Object { Write-Host "  - $($_.Name)" }
    Get-ChildItem -Path $OutputPath -Filter "*.dylib" -ErrorAction SilentlyContinue | ForEach-Object { Write-Host "  - $($_.Name)" }
    Get-ChildItem -Path $OutputPath -Filter "*.a" -ErrorAction SilentlyContinue | ForEach-Object { Write-Host "  - $($_.Name)" }
}
finally {
    Pop-Location
}

# Step 4: Copy library to Flutter build directories
Write-Header "Step 4: Copying libraries to Flutter build directories"

# Windows
if ($IsWindows -or $env:OS -eq "Windows_NT") {
    $SourceDll = Join-Path $TargetDir "release/$WinDllName"
    
    if (Test-Path $SourceDll) {
        New-Item -ItemType Directory -Force -Path $WinRunnerDebug | Out-Null
        New-Item -ItemType Directory -Force -Path $WinRunnerRelease | Out-Null
        
        Write-Step "Copying $WinDllName to Windows runner folders..."
        Copy-Item $SourceDll -Destination $WinRunnerDebug -Force
        Copy-Item $SourceDll -Destination $WinRunnerRelease -Force
        
        Write-Success "Windows DLL copied to:"
        Write-Host "    $WinRunnerDebug\$WinDllName" -ForegroundColor Gray
        Write-Host "    $WinRunnerRelease\$WinDllName" -ForegroundColor Gray
    }
    else {
        Write-Error "Windows DLL not found at $SourceDll"
        exit 1
    }
}

# Linux
if ($IsLinux) {
    $SourceSo = Join-Path $TargetDir "release/$LinuxSoName"
    $LinuxDest = Join-Path $ProjectRoot "build/linux/x64/runner/release"
    
    if (Test-Path $SourceSo) {
        New-Item -ItemType Directory -Force -Path $LinuxDest | Out-Null
        Write-Step "Copying $LinuxSoName to Linux runner..."
        Copy-Item $SourceSo -Destination $LinuxDest -Force
        Write-Success "Linux library copied to: $LinuxDest"
    }
    else {
        Write-Error "Linux SO not found at $SourceSo"
        exit 1
    }
}

# macOS
if ($IsMacOS) {
    $SourceDylib = Join-Path $TargetDir "release/$MacDylibName"
    $MacDest = Join-Path $ProjectRoot "build/macos/Build/Products/Release"
    
    if (Test-Path $SourceDylib) {
        New-Item -ItemType Directory -Force -Path $MacDest | Out-Null
        Write-Step "Copying $MacDylibName to macOS build..."
        Copy-Item $SourceDylib -Destination $MacDest -Force
        Write-Success "macOS library copied to: $MacDest"
    }
    else {
        Write-Error "macOS dylib not found at $SourceDylib"
        exit 1
    }
}

Write-Success "Copy operation completed"

Write-Header "Build script completed successfully"
Write-Host "All steps completed: Clean → Bindings → Release Build → Copy" -ForegroundColor Green
