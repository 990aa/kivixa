# build_math.ps1
# Build script for the kivixa_math native library
# Builds for Windows and Android only

param(
    [switch]$SkipAndroid,
    [switch]$SkipWindows,
    [switch]$SkipClean,
    [switch]$SkipBindings
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$MathRoot = Join-Path $ProjectRoot "native_math"
$TargetDir = Join-Path $MathRoot "target"

# Library names
$LibName = "kivixa_math"
$WinDllName = "$LibName.dll"
$AndroidSoName = "lib$LibName.so"

# Windows target
$WinTarget = "x86_64-pc-windows-msvc"

# Android targets
$AndroidArm64Target = "aarch64-linux-android"
$AndroidArmv7Target = "armv7-linux-androideabi"

# Destination directories for Windows
$WinRunnerDebug = Join-Path $ProjectRoot "build/windows/x64/runner/Debug"
$WinRunnerRelease = Join-Path $ProjectRoot "build/windows/x64/runner/Release"
$WinRunnerProfile = Join-Path $ProjectRoot "build/windows/x64/runner/Profile"

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

function Write-Err {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

# Step 1: Clean build artifacts
Write-Header "Step 1: Cleaning build artifacts"

if (-not $SkipClean) {
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
} else {
    Write-Host "Skipping clean (SkipClean flag set)" -ForegroundColor DarkYellow
}

# Step 2: Generate Flutter Rust Bridge bindings
if (-not $SkipBindings) {
    Write-Header "Step 2: Generating Flutter Rust Bridge bindings"

    Push-Location $ProjectRoot
    try {
        Write-Step "Running flutter_rust_bridge_codegen..."
        flutter_rust_bridge_codegen generate --config-file flutter_rust_bridge_math.yaml
        
        if ($LASTEXITCODE -ne 0) {
            Write-Err "Failed to generate bindings"
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
} else {
    Write-Host "Skipping bindings generation (SkipBindings flag set)" -ForegroundColor DarkYellow
}

# Step 3: Build the Rust library for Windows
if (-not $SkipWindows) {
    Write-Header "Step 3a: Building kivixa_math library for Windows ($WinTarget)"

    Push-Location $MathRoot
    try {
        Write-Step "Building in release mode for Windows..."
        cargo build --release --target $WinTarget
        
        if ($LASTEXITCODE -ne 0) {
            Write-Err "Windows build failed"
            exit 1
        }
        
        Write-Success "Windows build completed successfully"
        
        $SourceDll = Join-Path $TargetDir "$WinTarget/release/$WinDllName"
        
        if (Test-Path $SourceDll) {
            New-Item -ItemType Directory -Force -Path $WinRunnerDebug | Out-Null
            New-Item -ItemType Directory -Force -Path $WinRunnerRelease | Out-Null
            New-Item -ItemType Directory -Force -Path $WinRunnerProfile | Out-Null
            
            Write-Step "Copying $WinDllName to all Windows runner folders..."
            Copy-Item $SourceDll -Destination $WinRunnerDebug -Force
            Copy-Item $SourceDll -Destination $WinRunnerRelease -Force
            Copy-Item $SourceDll -Destination $WinRunnerProfile -Force
            
            Write-Success "Windows DLL copied to:"
            Write-Host "    $WinRunnerDebug\$WinDllName" -ForegroundColor Gray
            Write-Host "    $WinRunnerRelease\$WinDllName" -ForegroundColor Gray
            Write-Host "    $WinRunnerProfile\$WinDllName" -ForegroundColor Gray
        }
        else {
            Write-Err "Windows DLL not found at $SourceDll"
            exit 1
        }
    }
    finally {
        Pop-Location
    }
} else {
    Write-Host "Skipping Windows build (SkipWindows flag set)" -ForegroundColor DarkYellow
}

# Step 4: Build for Android
if (-not $SkipAndroid) {
    Write-Header "Step 3b: Building kivixa_math library for Android"

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
        Write-Err "Android NDK not found. Set ANDROID_NDK_HOME environment variable."
        Write-Host "Skipping Android build..." -ForegroundColor Yellow
    }
    else {
        Write-Host "Using Android NDK: $ndkPath" -ForegroundColor Gray

        # Set up toolchain paths for NDK r25+
        $toolchainDir = Join-Path $ndkPath "toolchains\llvm\prebuilt\windows-x86_64"
        $binDir = Join-Path $toolchainDir "bin"
        
        # API level (minimum 23 for most features)
        $apiLevel = 23

        # Set environment for cross-compilation
        $env:PATH = "$binDir;$env:PATH"
        $env:ANDROID_NDK = $ndkPath
        $env:ANDROID_NDK_ROOT = $ndkPath
        $env:ANDROID_PLATFORM = "android-$apiLevel"
        $env:CLANG_PATH = $null

        Push-Location $MathRoot
        try {
            # arm64-v8a
            Write-Step "Building for Android arm64-v8a ($AndroidArm64Target)..."
            $env:CC_aarch64_linux_android = Join-Path $binDir "aarch64-linux-android$apiLevel-clang.cmd"
            $env:AR_aarch64_linux_android = Join-Path $binDir "llvm-ar.exe"
            $env:CARGO_TARGET_AARCH64_LINUX_ANDROID_LINKER = Join-Path $binDir "aarch64-linux-android$apiLevel-clang.cmd"
            cargo build --release --target $AndroidArm64Target

            if ($LASTEXITCODE -ne 0) {
                Write-Err "Android arm64-v8a build failed"
                exit 1
            }

            # armeabi-v7a
            Write-Step "Building for Android armeabi-v7a ($AndroidArmv7Target)..."
            $env:CC_armv7_linux_androideabi = Join-Path $binDir "armv7a-linux-androideabi$apiLevel-clang.cmd"
            $env:AR_armv7_linux_androideabi = Join-Path $binDir "llvm-ar.exe"
            $env:CARGO_TARGET_ARMV7_LINUX_ANDROIDEABI_LINKER = Join-Path $binDir "armv7a-linux-androideabi$apiLevel-clang.cmd"
            cargo build --release --target $AndroidArmv7Target

            if ($LASTEXITCODE -ne 0) {
                Write-Err "Android armeabi-v7a build failed"
                exit 1
            }

            Write-Success "Android builds completed successfully"

            # Copy to jniLibs
            $SourceArm64So = Join-Path $TargetDir "$AndroidArm64Target/release/$AndroidSoName"
            $SourceArmv7So = Join-Path $TargetDir "$AndroidArmv7Target/release/$AndroidSoName"

            if ((Test-Path $SourceArm64So) -and (Test-Path $SourceArmv7So)) {
                New-Item -ItemType Directory -Force -Path $JniArm64Dir | Out-Null
                New-Item -ItemType Directory -Force -Path $JniArmv7Dir | Out-Null

                Write-Step "Copying Android .so files to jniLibs..."
                Copy-Item $SourceArm64So -Destination $JniArm64Dir -Force
                Copy-Item $SourceArmv7So -Destination $JniArmv7Dir -Force

                Write-Success "Android SOs copied to:"
                Write-Host "    $JniArm64Dir\$AndroidSoName" -ForegroundColor Gray
                Write-Host "    $JniArmv7Dir\$AndroidSoName" -ForegroundColor Gray
            }
            else {
                Write-Err "Android .so files not found"
                exit 1
            }
        }
        finally {
            Pop-Location
        }
    }
} else {
    Write-Host "Skipping Android build (SkipAndroid flag set)" -ForegroundColor DarkYellow
}

Write-Success "Build operations completed"

Write-Header "Build script completed successfully"
Write-Host "All steps completed: Clean → Bindings → Windows Build → Android Build → Copy" -ForegroundColor Green
