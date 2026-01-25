# build_math.ps1
# Build script for the kivixa_math native library
# Isolated from the main AI inference native module

param(
    [switch]$Release,
    [switch]$GenerateBindings,
    [switch]$Clean,
    [switch]$All
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$MathRoot = Join-Path $ProjectRoot "native_math"
$TargetDir = Join-Path $MathRoot "target"

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

# Copy library to Flutter build directory (Windows)
if ($All -and $IsWindows) {
    Write-Header "Copying library for Flutter (Windows)"
    
    $BuildMode = if ($Release) { "release" } else { "debug" }
    $SourceDll = Join-Path $TargetDir "$BuildMode/kivixa_math.dll"
    $DestDir = Join-Path $ProjectRoot "build/windows/x64/runner/$BuildMode"
    
    if (Test-Path $SourceDll) {
        if (-not (Test-Path $DestDir)) {
            New-Item -ItemType Directory -Force -Path $DestDir | Out-Null
        }
        
        Write-Step "Copying kivixa_math.dll to Flutter build..."
        Copy-Item $SourceDll -Destination $DestDir -Force
        Write-Success "Library copied successfully"
    }
    else {
        Write-Host "Note: DLL not found at $SourceDll (build Flutter app first)" -ForegroundColor Gray
    }
}

Write-Header "Build script completed"

# Usage instructions
if (-not $Clean -and -not $GenerateBindings -and -not $Release -and -not $All) {
    Write-Host @"
Usage:
  .\build_math.ps1                    # Debug build
  .\build_math.ps1 -Release           # Release build
  .\build_math.ps1 -GenerateBindings  # Generate FRB bindings only
  .\build_math.ps1 -Clean             # Clean build artifacts
  .\build_math.ps1 -All               # Clean + Generate bindings + Release build

"@ -ForegroundColor Gray
}
