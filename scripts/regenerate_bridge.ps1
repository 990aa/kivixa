<#
.SYNOPSIS
    Regenerates the flutter_rust_bridge bindings for Kivixa (Core, Math, and Audio)
    and purges all unnecessary boilerplate to keep the CI environment stable.
    
    Location: scripts/regenerate_bridge.ps1
#>

# 1. Determine the root directory (one level up from this script)
$rootDir = Split-Path -Path $PSScriptRoot -Parent
Set-Location -Path $rootDir

Write-Host "`n=== Kivixa Bridge Regeneration & Cleanup Module ===" -ForegroundColor Cyan
Write-Host "Root Directory: $rootDir" -ForegroundColor Gray

function Assert-LastExitCode {
    param(
        [string]$Context
    )

    if ($LASTEXITCODE -ne 0) {
        Write-Error "$Context failed with exit code $LASTEXITCODE"
        exit $LASTEXITCODE
    }
}

# ---------------------------------------------------------
# STEP 1: REGENERATE BINDINGS
# ---------------------------------------------------------
Write-Host "`nStep 1: Running flutter_rust_bridge_codegen..." -ForegroundColor Yellow

# Core AI/Native Module
Write-Host "  > Core Bindings..." -NoNewline
flutter_rust_bridge_codegen generate
Assert-LastExitCode "Core binding generation"
Write-Host " Done." -ForegroundColor Green

# Math Module
Write-Host "  > Math Bindings..." -NoNewline
flutter_rust_bridge_codegen generate --config-file flutter_rust_bridge_math.yaml
Assert-LastExitCode "Math binding generation"
Write-Host " Done." -ForegroundColor Green

# Audio Module
Write-Host "  > Audio Bindings..." -NoNewline
flutter_rust_bridge_codegen generate --config-file flutter_rust_bridge_audio.yaml
Assert-LastExitCode "Audio binding generation"
Write-Host " Done." -ForegroundColor Green


# ---------------------------------------------------------
# STEP 2: PURGE BOILERPLATE
# ---------------------------------------------------------
Write-Host "`nStep 2: Cleaning rust_builder directory..." -ForegroundColor Yellow
$rustBuilderDir = Join-Path $rootDir "rust_builder"
if (-not (Test-Path -LiteralPath $rustBuilderDir -PathType Container)) {
    Write-Error "Expected directory not found: $rustBuilderDir"
    exit 1
}

Set-Location -LiteralPath $rustBuilderDir -ErrorAction Stop

if (-not (Test-Path -LiteralPath (Join-Path $rustBuilderDir "pubspec.yaml") -PathType Leaf)) {
    Write-Error "Safety check failed: rust_builder/pubspec.yaml not found in $rustBuilderDir"
    exit 1
}

# These items are deleted to prevent them from being tracked by Git
# and to ensure the Android/Windows CI remains 100% isolated.
$purgeList = @(
    "android", 
    "windows", 
    "lib", 
    "test", 
    "example",
    ".gitignore", 
    ".metadata", 
    "CHANGELOG.md", 
    "LICENSE", 
    "analysis_options.yaml"
)

foreach ($item in $purgeList) {
    if (Test-Path -LiteralPath $item) {
        try {
            Remove-Item -LiteralPath $item -Recurse -Force -ErrorAction Stop
            Write-Host "  [PURGED] $item"
        }
        catch {
            Write-Error "Failed to purge '$item': $($_.Exception.Message)"
            exit 1
        }
    }
}

# ---------------------------------------------------------
# FINAL STATUS
# ---------------------------------------------------------
Write-Host "`n=== Success! Your bridge is updated and the codebase is clean. ===`n" -ForegroundColor Green
Write-Host "To commit changes, run:" -ForegroundColor Gray
Write-Host "git add . && git commit -m 'feat: regenerate native bridge'" -ForegroundColor Gray