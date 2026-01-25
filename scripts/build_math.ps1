# build_math.ps1
# Build script for the kivixa_math native library
# Isolated from the main AI inference native module

param(
    [switch]$Release,
    [switch]$GenerateBindings,
    [switch]$Clean,
    [switch]$Copy,
    [switch]$All
)

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

# Clean build artifacts
if ($Clean -or $All) {
    Write-Header "Cleaning build artifacts"
    
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
}

# Generate Flutter Rust Bridge bindings
if ($GenerateBindings -or $All) {
    Write-Header "Generating Flutter Rust Bridge bindings"
    
    Push-Location $ProjectRoot
    try {
        Write-Step "Running flutter_rust_bridge_codegen..."
        flutter_rust_bridge_codegen generate --config-file flutter_rust_bridge_math.yaml
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to generate bindings"
            exit 1
        }
        
        Write-Success "Bindings generated successfully"
    }
    finally {
        Pop-Location
    }
}

# Build the Rust library
if (-not $Clean -or $All) {
    Write-Header "Building kivixa_math library"
    
    Push-Location $MathRoot
    try {
        if ($Release) {
            Write-Step "Building in release mode..."
            cargo build --release
        }
        else {
            Write-Step "Building in debug mode..."
            cargo build
        }
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Build failed"
            exit 1
        }
        
        Write-Success "Build completed successfully"
        
        # Show output location
        $BuildMode = if ($Release) { "release" } else { "debug" }
        $OutputPath = Join-Path $TargetDir $BuildMode
        Write-Host "`nOutput location: $OutputPath" -ForegroundColor Gray
        
        # List built libraries
        Write-Step "Built artifacts:"
        Get-ChildItem -Path $OutputPath -Filter "*.dll" -ErrorAction SilentlyContinue | ForEach-Object { Write-Host "  - $($_.Name)" }
        Get-ChildItem -Path $OutputPath -Filter "*.so" -ErrorAction SilentlyContinue | ForEach-Object { Write-Host "  - $($_.Name)" }
        Get-ChildItem -Path $OutputPath -Filter "*.dylib" -ErrorAction SilentlyContinue | ForEach-Object { Write-Host "  - $($_.Name)" }
        Get-ChildItem -Path $OutputPath -Filter "*.a" -ErrorAction SilentlyContinue | ForEach-Object { Write-Host "  - $($_.Name)" }
    }
    finally {
        Pop-Location
    }
}

# Copy library to Flutter build directories
if ($Copy -or $All) {
    Write-Header "Copying libraries to Flutter build directories"
    
    $BuildMode = if ($Release) { "release" } else { "debug" }
    
    # Windows
    if ($IsWindows -or $env:OS -eq "Windows_NT") {
        $SourceDll = Join-Path $TargetDir "$BuildMode/$WinDllName"
        
        if (Test-Path $SourceDll) {
            # Ensure directories exist
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
            Write-Host "Warning: Windows DLL not found at $SourceDll" -ForegroundColor Yellow
            Write-Host "  Build the library first with: .\build_math.ps1 -Release" -ForegroundColor Gray
        }
    }
    
    # Linux
    if ($IsLinux) {
        $SourceSo = Join-Path $TargetDir "$BuildMode/$LinuxSoName"
        $LinuxDest = Join-Path $ProjectRoot "build/linux/x64/runner/$BuildMode"
        
        if (Test-Path $SourceSo) {
            New-Item -ItemType Directory -Force -Path $LinuxDest | Out-Null
            Write-Step "Copying $LinuxSoName to Linux runner..."
            Copy-Item $SourceSo -Destination $LinuxDest -Force
            Write-Success "Linux library copied to: $LinuxDest"
        }
        else {
            Write-Host "Warning: Linux SO not found at $SourceSo" -ForegroundColor Yellow
        }
    }
    
    # macOS
    if ($IsMacOS) {
        $SourceDylib = Join-Path $TargetDir "$BuildMode/$MacDylibName"
        $MacDest = Join-Path $ProjectRoot "build/macos/Build/Products/$BuildMode"
        
        if (Test-Path $SourceDylib) {
            New-Item -ItemType Directory -Force -Path $MacDest | Out-Null
            Write-Step "Copying $MacDylibName to macOS build..."
            Copy-Item $SourceDylib -Destination $MacDest -Force
            Write-Success "macOS library copied to: $MacDest"
        }
        else {
            Write-Host "Warning: macOS dylib not found at $SourceDylib" -ForegroundColor Yellow
        }
    }
    
    Write-Success "Copy operation completed"
}

Write-Header "Build script completed"

# Usage instructions
if (-not $Clean -and -not $GenerateBindings -and -not $Release -and -not $Copy -and -not $All) {
    Write-Host @"
Usage:
  .\build_math.ps1                    # Debug build
  .\build_math.ps1 -Release           # Release build  
  .\build_math.ps1 -Copy              # Copy built libraries to Flutter directories
  .\build_math.ps1 -GenerateBindings  # Generate FRB bindings only
  .\build_math.ps1 -Clean             # Clean build artifacts
  .\build_math.ps1 -All               # Clean + Generate bindings + Release build + Copy
  .\build_math.ps1 -Release -Copy     # Release build and copy

"@ -ForegroundColor Gray
}
