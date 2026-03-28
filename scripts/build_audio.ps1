# build_audio.ps1
# Build script for the kivixa_audio native library
# Builds for Windows and Android only
# Audio Intelligence Module: STT (Whisper), TTS (Kokoro), VAD, Ring Buffer

param(
    [switch]$SkipAndroid,
    [switch]$SkipWindows,
    [switch]$SkipClean,
    [switch]$SkipBindings,
    [switch]$SkipTests,
    [switch]$Release,
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$AudioRoot = Join-Path $ProjectRoot "native_audio"
$TargetDir = Join-Path $AudioRoot "target"

# Library names
$LibName = "kivixa_audio"
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

# rust_builder plugin directories
$RustBuilderBase = Join-Path $ProjectRoot "rust_builder"
$RustBuilderAndroid = Join-Path $RustBuilderBase "android/src/main/jniLibs"
$RustBuilderWindows = Join-Path $RustBuilderBase "windows"

function Write-Header {
    param([string]$Message)
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "🔊 $Message" -ForegroundColor Cyan
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

function Write-VerboseMsg {
    param([string]$Message)
    if ($Verbose) {
        Write-Host "  [DEBUG] $Message" -ForegroundColor DarkGray
    }
}

# Check if Cargo.toml exists
if (-not (Test-Path (Join-Path $AudioRoot "Cargo.toml"))) {
    Write-Err "Cargo.toml not found in $AudioRoot"
    Write-Host "Please ensure the native_audio directory exists with a valid Rust project." -ForegroundColor Yellow
    exit 1
}

Write-Header "Kivixa Audio Intelligence Build Script"
Write-Host "Building: STT (Whisper), TTS (Kokoro), VAD, Audio Buffer" -ForegroundColor Gray
Write-Host "Project Root: $ProjectRoot" -ForegroundColor Gray

# Step 1: Clean build artifacts
Write-Header "Step 1: Cleaning build artifacts"

if (-not $SkipClean) {
    if (Test-Path $TargetDir) {
        Write-Step "Removing target directory..."
        Remove-Item -Recurse -Force $TargetDir
    }

    $DartOutput = Join-Path $ProjectRoot "lib/src/rust_audio"
    if (Test-Path $DartOutput) {
        Write-Step "Removing generated Dart files..."
        Remove-Item -Recurse -Force $DartOutput
    }

    Write-Success "Clean completed"
} else {
    Write-Host "Skipping clean (SkipClean flag set)" -ForegroundColor DarkYellow
}

# Step 2: Run tests
if (-not $SkipTests) {
    Write-Header "Step 2: Running Tests"
    
    Push-Location $AudioRoot
    try {
        Write-Step "Running cargo test..."
        cargo test --all-features 2>&1 | ForEach-Object { Write-Host "    $_" }
        
        if ($LASTEXITCODE -ne 0) {
            Write-Err "Tests failed! Fix the tests before building."
            exit 1
        }
        
        Write-Success "All tests passed"
    }
    finally {
        Pop-Location
    }
} else {
    Write-Host "Skipping tests (SkipTests flag set)" -ForegroundColor DarkYellow
}

# Step 3: Generate Flutter Rust Bridge bindings
if (-not $SkipBindings) {
    Write-Header "Step 3: Generating Flutter Rust Bridge bindings"

    Push-Location $ProjectRoot
    try {
        Write-Step "Running flutter_rust_bridge_codegen..."
        flutter_rust_bridge_codegen generate --config-file flutter_rust_bridge_audio.yaml 2>&1 | ForEach-Object { Write-Host "    $_" }
        
        if ($LASTEXITCODE -ne 0) {
            Write-Err "Failed to generate bindings"
            Write-Host "Note: Binding generation may fail if flutter_rust_bridge_codegen is not installed." -ForegroundColor Yellow
            Write-Host "Install with: cargo install flutter_rust_bridge_codegen" -ForegroundColor Yellow
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

# Determine build mode
$BuildMode = if ($Release) { "release" } else { "release" } # Always use release for native libs
$CargoArgs = @("build", "--$BuildMode")

# Step 4: Build the Rust library for Windows
if (-not $SkipWindows) {
    Write-Header "Step 4a: Building kivixa_audio library for Windows ($WinTarget)"

    Push-Location $AudioRoot
    try {
        Write-Step "Building in $BuildMode mode for Windows..."
        $args = $CargoArgs + @("--target", $WinTarget)
        Write-VerboseMsg "Command: cargo $($args -join ' ')"
        
        cargo @args 2>&1 | ForEach-Object { Write-Host "    $_" }
        
        if ($LASTEXITCODE -ne 0) {
            Write-Err "Windows build failed"
            exit 1
        }
        
        Write-Success "Windows build completed successfully"
        
        $SourceDll = Join-Path $TargetDir "$WinTarget/$BuildMode/$WinDllName"
        
        if (Test-Path $SourceDll) {
            # Create destination directories
            @($WinRunnerDebug, $WinRunnerRelease, $WinRunnerProfile) | ForEach-Object {
                New-Item -ItemType Directory -Force -Path $_ | Out-Null
            }
            
            Write-Step "Copying $WinDllName to Windows runner folders..."
            Copy-Item $SourceDll -Destination $WinRunnerDebug -Force
            Copy-Item $SourceDll -Destination $WinRunnerRelease -Force
            Copy-Item $SourceDll -Destination $WinRunnerProfile -Force
            
            # Also copy to rust_builder plugin if it exists
            if (Test-Path $RustBuilderWindows) {
                Write-Step "Copying to rust_builder plugin..."
                Copy-Item $SourceDll -Destination $RustBuilderWindows -Force
            }
            
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

# Step 5: Build for Android
if (-not $SkipAndroid) {
    Write-Header "Step 4b: Building kivixa_audio library for Android"

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

        Push-Location $AudioRoot
        try {
            # arm64-v8a
            Write-Step "Building for Android arm64-v8a ($AndroidArm64Target)..."
            $env:CC_aarch64_linux_android = Join-Path $binDir "aarch64-linux-android$apiLevel-clang.cmd"
            $env:AR_aarch64_linux_android = Join-Path $binDir "llvm-ar.exe"
            $env:CARGO_TARGET_AARCH64_LINUX_ANDROID_LINKER = Join-Path $binDir "aarch64-linux-android$apiLevel-clang.cmd"
            
            $args = $CargoArgs + @("--target", $AndroidArm64Target)
            cargo @args 2>&1 | ForEach-Object { Write-Host "    $_" }

            if ($LASTEXITCODE -ne 0) {
                Write-Err "Android arm64-v8a build failed"
                exit 1
            }

            # armeabi-v7a
            Write-Step "Building for Android armeabi-v7a ($AndroidArmv7Target)..."
            $env:CC_armv7_linux_androideabi = Join-Path $binDir "armv7a-linux-androideabi$apiLevel-clang.cmd"
            $env:AR_armv7_linux_androideabi = Join-Path $binDir "llvm-ar.exe"
            $env:CARGO_TARGET_ARMV7_LINUX_ANDROIDEABI_LINKER = Join-Path $binDir "armv7a-linux-androideabi$apiLevel-clang.cmd"
            
            $args = $CargoArgs + @("--target", $AndroidArmv7Target)
            cargo @args 2>&1 | ForEach-Object { Write-Host "    $_" }

            if ($LASTEXITCODE -ne 0) {
                Write-Err "Android armeabi-v7a build failed"
                exit 1
            }

            Write-Success "Android builds completed successfully"

            # Copy to jniLibs
            $SourceArm64So = Join-Path $TargetDir "$AndroidArm64Target/$BuildMode/$AndroidSoName"
            $SourceArmv7So = Join-Path $TargetDir "$AndroidArmv7Target/$BuildMode/$AndroidSoName"

            if ((Test-Path $SourceArm64So) -and (Test-Path $SourceArmv7So)) {
                # Create jniLibs directories
                New-Item -ItemType Directory -Force -Path $JniArm64Dir | Out-Null
                New-Item -ItemType Directory -Force -Path $JniArmv7Dir | Out-Null

                Write-Step "Copying Android .so files to jniLibs..."
                Copy-Item $SourceArm64So -Destination $JniArm64Dir -Force
                Copy-Item $SourceArmv7So -Destination $JniArmv7Dir -Force

                # Also copy to rust_builder plugin if it exists
                $RustBuilderArm64 = Join-Path $RustBuilderAndroid "arm64-v8a"
                $RustBuilderArmv7 = Join-Path $RustBuilderAndroid "armeabi-v7a"
                
                if (Test-Path (Split-Path $RustBuilderAndroid)) {
                    New-Item -ItemType Directory -Force -Path $RustBuilderArm64 | Out-Null
                    New-Item -ItemType Directory -Force -Path $RustBuilderArmv7 | Out-Null
                    
                    Write-Step "Copying to rust_builder plugin..."
                    Copy-Item $SourceArm64So -Destination $RustBuilderArm64 -Force
                    Copy-Item $SourceArmv7So -Destination $RustBuilderArmv7 -Force
                }

                Write-Success "Android SOs copied to:"
                Write-Host "    $JniArm64Dir\$AndroidSoName" -ForegroundColor Gray
                Write-Host "    $JniArmv7Dir\$AndroidSoName" -ForegroundColor Gray
            }
            else {
                Write-Err "Android .so files not found"
                Write-VerboseMsg "Expected: $SourceArm64So"
                Write-VerboseMsg "Expected: $SourceArmv7So"
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

# Summary
Write-Header "Build Summary"

Write-Host "Library: $LibName" -ForegroundColor White
Write-Host "Build Mode: $BuildMode" -ForegroundColor White
Write-Host ""

if (-not $SkipWindows) {
    Write-Host "Windows:" -ForegroundColor Cyan
    Write-Host "  ✓ $WinTarget" -ForegroundColor Green
}

if (-not $SkipAndroid) {
    Write-Host "Android:" -ForegroundColor Cyan
    Write-Host "  ✓ $AndroidArm64Target (arm64-v8a)" -ForegroundColor Green
    Write-Host "  ✓ $AndroidArmv7Target (armeabi-v7a)" -ForegroundColor Green
}

Write-Host ""
Write-Success "Build script completed successfully!"
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Run 'flutter pub get' to ensure dependencies are synced" -ForegroundColor Gray
Write-Host "  2. Run 'flutter run' to test the application" -ForegroundColor Gray
Write-Host "  3. Use AudioRustLib in Dart to access audio features" -ForegroundColor Gray
