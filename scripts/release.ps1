<#
.SYNOPSIS
    One-click release trigger for Kivixa.
    
.DESCRIPTION
    This script:
    1. Reads VERSION file to get current version
    2. Commits any pending changes
    3. Creates and pushes the tag
    4. GitHub Actions handles the rest (build, release, README update)
    5. Pulls the updated README back to local
    
.PARAMETER DryRun
    If specified, shows what would happen without making changes.
    
.PARAMETER BumpPatch
    Bumps the patch version before releasing (0.1.5 -> 0.1.6)
    
.PARAMETER BumpMinor
    Bumps the minor version before releasing (0.1.5 -> 0.2.0)
    
.EXAMPLE
    .\release.ps1
    
.EXAMPLE
    .\release.ps1 -BumpPatch
    
.EXAMPLE
    .\release.ps1 -DryRun
#>

param(
    [switch]$DryRun,
    [switch]$BumpPatch,
    [switch]$BumpMinor
)

$ErrorActionPreference = "Stop"

# Get project root
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
Set-Location $projectRoot

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "    Kivixa Release Trigger" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Read current version
Write-Host "[1/5] Reading VERSION file..." -ForegroundColor Yellow

$versionFile = Join-Path $projectRoot "VERSION"
if (-not (Test-Path $versionFile)) {
    throw "VERSION file not found at $versionFile"
}

$versionContent = Get-Content $versionFile -Raw
$major = [int]([regex]::Match($versionContent, 'MAJOR=(\d+)').Groups[1].Value)
$minor = [int]([regex]::Match($versionContent, 'MINOR=(\d+)').Groups[1].Value)
$patch = [int]([regex]::Match($versionContent, 'PATCH=(\d+)').Groups[1].Value)
$buildNumber = [int]([regex]::Match($versionContent, 'BUILD_NUMBER=(\d+)').Groups[1].Value)

Write-Host "  Current: $major.$minor.$patch+$buildNumber" -ForegroundColor Gray

# Step 2: Bump version if requested
if ($BumpMinor) {
    $minor++
    $patch = 0
    $buildNumber = $major * 100000 + $minor * 1000 + $patch
    Write-Host "  Bumping MINOR version..." -ForegroundColor Yellow
} elseif ($BumpPatch) {
    $patch++
    $buildNumber = $major * 100000 + $minor * 1000 + $patch
    Write-Host "  Bumping PATCH version..." -ForegroundColor Yellow
}

$version = "$major.$minor.$patch"
$tagName = "v$version+$buildNumber"

Write-Host "  Release: $version+$buildNumber" -ForegroundColor Green
Write-Host "  Tag:     $tagName" -ForegroundColor Green
Write-Host ""

# Step 3: Update VERSION file if bumped
if ($BumpPatch -or $BumpMinor) {
    Write-Host "[2/5] Updating VERSION file..." -ForegroundColor Yellow
    
    $newVersionContent = @"
# Kivixa Version File
# This file maintains the single source of truth for version numbers.
# Run `dart run scripts/bump_version.dart` to update all version references.

MAJOR=$major
MINOR=$minor
PATCH=$patch
BUILD_NUMBER=$buildNumber

"@
    
    if (-not $DryRun) {
        $newVersionContent | Set-Content $versionFile -NoNewline
        Write-Host "  VERSION file updated" -ForegroundColor Green
        
        # Also update pubspec.yaml
        $pubspecFile = Join-Path $projectRoot "pubspec.yaml"
        $pubspecContent = Get-Content $pubspecFile -Raw
        $pubspecContent = $pubspecContent -replace '^version: .*', "version: $version+$buildNumber"
        $pubspecContent | Set-Content $pubspecFile -NoNewline
        Write-Host "  pubspec.yaml updated" -ForegroundColor Green
    } else {
        Write-Host "  [DRY RUN] Would update VERSION file" -ForegroundColor Magenta
    }
} else {
    Write-Host "[2/5] No version bump requested" -ForegroundColor DarkGray
}
Write-Host ""

# Step 4: Git operations
Write-Host "[3/5] Git operations..." -ForegroundColor Yellow

# Check for changes
$gitStatus = git status --porcelain
if ($gitStatus) {
    Write-Host "  Uncommitted changes found:" -ForegroundColor Yellow
    $gitStatus | Select-Object -First 5 | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkYellow }
    if (($gitStatus | Measure-Object).Count -gt 5) {
        Write-Host "    ... and more" -ForegroundColor DarkYellow
    }
    
    if (-not $DryRun) {
        git add .
        git commit -m "chore: release v$version"
        Write-Host "  Changes committed" -ForegroundColor Green
    } else {
        Write-Host "  [DRY RUN] Would commit changes" -ForegroundColor Magenta
    }
}

# Check if tag exists
$existingTag = git tag -l $tagName
if ($existingTag) {
    Write-Host "  Warning: Tag $tagName already exists!" -ForegroundColor Red
    $confirm = Read-Host "  Delete and recreate? (y/N)"
    if ($confirm -eq 'y' -or $confirm -eq 'Y') {
        if (-not $DryRun) {
            git tag -d $tagName 2>$null
            git push origin --delete $tagName 2>$null
            Write-Host "  Old tag deleted" -ForegroundColor Yellow
        }
    } else {
        throw "Aborted: Tag already exists"
    }
}

# Create and push tag
if (-not $DryRun) {
    Write-Host "  Creating tag $tagName..." -ForegroundColor Yellow
    git tag -a $tagName -m "Release $version"
    
    Write-Host "  Pushing to origin..." -ForegroundColor Yellow
    git push origin
    git push origin $tagName
    
    Write-Host "  Tag pushed successfully!" -ForegroundColor Green
} else {
    Write-Host "  [DRY RUN] Would create tag: $tagName" -ForegroundColor Magenta
    Write-Host "  [DRY RUN] Would push to origin" -ForegroundColor Magenta
}
Write-Host ""

# Step 5: Wait for GitHub Actions
Write-Host "[4/5] GitHub Actions Triggered!" -ForegroundColor Yellow
Write-Host ""
Write-Host "  The workflow will now:" -ForegroundColor Gray
Write-Host "    1. Build Rust native libraries" -ForegroundColor Gray
Write-Host "    2. Build Android APKs (arm64, armv7, x86_64)" -ForegroundColor Gray
Write-Host "    3. Build Windows installer" -ForegroundColor Gray
Write-Host "    4. Create GitHub Release" -ForegroundColor Gray
Write-Host "    5. Update F-Droid repository" -ForegroundColor Gray
Write-Host "    6. Submit to Winget" -ForegroundColor Gray
Write-Host "    7. Update README.md with download links" -ForegroundColor Gray
Write-Host ""

if (-not $DryRun) {
    Write-Host "  Watch progress at:" -ForegroundColor Cyan
    Write-Host "  https://github.com/990aa/kivixa/actions" -ForegroundColor White
    Write-Host ""
    
    $waitForReadme = Read-Host "  Wait for workflow to complete and sync README? (y/N)"
    if ($waitForReadme -eq 'y' -or $waitForReadme -eq 'Y') {
        Write-Host ""
        Write-Host "[5/5] Waiting for workflow completion..." -ForegroundColor Yellow
        Write-Host "  Press Ctrl+C to stop waiting and sync manually later" -ForegroundColor DarkGray
        Write-Host ""
        
        # Poll for workflow completion (check README changes)
        $maxWaitMinutes = 30
        $waitIntervalSeconds = 30
        $waited = 0
        $maxWaitSeconds = $maxWaitMinutes * 60
        
        while ($waited -lt $maxWaitSeconds) {
            Start-Sleep -Seconds $waitIntervalSeconds
            $waited += $waitIntervalSeconds
            
            # Fetch and check for README changes
            git fetch origin
            $remoteDiff = git diff HEAD origin/main -- README.md 2>$null
            
            if ($remoteDiff) {
                Write-Host "  README.md updated on remote!" -ForegroundColor Green
                git pull origin main
                Write-Host "  Local repo synced!" -ForegroundColor Green
                break
            }
            
            $waitedMinutes = [math]::Floor($waited / 60)
            $waitedSecs = $waited % 60
            Write-Host "  Waiting... ($waitedMinutes`:$($waitedSecs.ToString('00')) elapsed)" -ForegroundColor DarkGray
        }
        
        if ($waited -ge $maxWaitSeconds) {
            Write-Host "  Timeout reached. Sync manually with: git pull origin main" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "  [DRY RUN] Would trigger workflow" -ForegroundColor Magenta
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "    Release Process Complete!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Version: $version" -ForegroundColor White
Write-Host "  Tag:     $tagName" -ForegroundColor White
Write-Host ""
if (-not $DryRun) {
    Write-Host "  Release URL:" -ForegroundColor Cyan
    Write-Host "  https://github.com/990aa/kivixa/releases/tag/$tagName" -ForegroundColor White
}
Write-Host ""
