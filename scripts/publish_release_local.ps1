<#
.SYNOPSIS
    Publishes a new Kivixa release to GitHub.

.DESCRIPTION
    This script automates the release process:
    1. Reads the version from VERSION file
    2. Creates a git tag and pushes it
    3. Extracts changelog notes for the version
    4. Renames and collects build artifacts
    5. Creates a GitHub release with the beta label

.PARAMETER DryRun
    If specified, shows what would be done without executing.

.EXAMPLE
    .\publish_release.ps1
    
.EXAMPLE
    .\publish_release.ps1 -DryRun
#>

param(
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

# Get project root (parent of scripts directory)
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Kivixa Release Publisher" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ============================================
# Step 1: Read version from VERSION file
# ============================================
Write-Host "[1/6] Reading version from VERSION file..." -ForegroundColor Yellow

$versionFile = Join-Path $projectRoot "VERSION"
if (-not (Test-Path $versionFile)) {
    throw "VERSION file not found at $versionFile"
}

$versionContent = Get-Content $versionFile -Raw
$major = [regex]::Match($versionContent, 'MAJOR=(\d+)').Groups[1].Value
$minor = [regex]::Match($versionContent, 'MINOR=(\d+)').Groups[1].Value
$patch = [regex]::Match($versionContent, 'PATCH=(\d+)').Groups[1].Value
$buildNumber = [regex]::Match($versionContent, 'BUILD_NUMBER=(\d+)').Groups[1].Value

if (-not $major -or -not $minor -or -not $patch) {
    throw "Could not parse version from VERSION file"
}

$version = "$major.$minor.$patch"
$tagName = "v$version+$buildNumber"
$releaseTitle = "v$version - Beta Release"

Write-Host "  Version: $version" -ForegroundColor Green
Write-Host "  Build Number: $buildNumber" -ForegroundColor Green
Write-Host "  Tag: $tagName" -ForegroundColor Green
Write-Host "  Release Title: $releaseTitle" -ForegroundColor Green
Write-Host ""

# ============================================
# Step 2: Extract changelog for this version
# ============================================
Write-Host "[2/6] Extracting changelog notes..." -ForegroundColor Yellow

$changelogFile = Join-Path $projectRoot "CHANGELOG.md"
if (-not (Test-Path $changelogFile)) {
    throw "CHANGELOG.md not found at $changelogFile"
}

$changelogContent = Get-Content $changelogFile -Raw

# Extract the section for this version
# Pattern: ## [X.Y.Z] - DATE followed by content until next ## or end
$pattern = "(?s)## \[$version\][^\r\n]*\r?\n(.*?)(?=\r?\n## \[|$)"
$match = [regex]::Match($changelogContent, $pattern)

if ($match.Success) {
    $releaseNotes = $match.Groups[1].Value.Trim()
    # Remove leading/trailing --- separators
    $releaseNotes = $releaseNotes -replace "^---\s*", ""
    $releaseNotes = $releaseNotes -replace "\s*---$", ""
    $releaseNotes = $releaseNotes.Trim()
} else {
    Write-Host "  Warning: Could not find changelog entry for version $version" -ForegroundColor Red
    $releaseNotes = "Release v$version"
}

Write-Host "  Release Notes Preview:" -ForegroundColor Green
Write-Host "  ----------------------" -ForegroundColor DarkGray
$releaseNotes.Split("`n") | Select-Object -First 10 | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
if (($releaseNotes.Split("`n")).Count -gt 10) {
    Write-Host "  ... (truncated)" -ForegroundColor DarkGray
}
Write-Host ""

# ============================================
# Step 3: Update README.md with download links
# ============================================
Write-Host "[3/7] Updating README.md download links..." -ForegroundColor Yellow

$readmeFile = Join-Path $projectRoot "README.md"
if (Test-Path $readmeFile) {
    $readmeContent = Get-Content $readmeFile -Raw
    $readmeModified = $false

    # URL encode the + sign for the tag
    $tagEncoded = "v$version%2B$buildNumber"
    $tagPlain = "v$version+$buildNumber"

    # Update Version badge
    $versionBadgePattern = '\[!\[Version\]\(https://img\.shields\.io/badge/Version-[^\)]+\)\]\(CHANGELOG\.md\)'
    $versionBadgeReplacement = "[![Version](https://img.shields.io/badge/Version-$version%2B$buildNumber--beta-orange)](CHANGELOG.md)"
    if ($readmeContent -match $versionBadgePattern) {
        $readmeContent = $readmeContent -replace $versionBadgePattern, $versionBadgeReplacement
        $readmeModified = $true
    }

    # Update Windows download link
    $windowsPattern = '\[!\[Download Windows\]\([^\)]+\)\]\(https://github\.com/990aa/kivixa/releases/download/[^/]+/Kivixa-Setup-[^\)]+\.exe\)'
    $windowsReplacement = "[![Download Windows](https://img.shields.io/badge/Download-Windows-2ea44f?logo=windows)](https://github.com/990aa/kivixa/releases/download/$tagEncoded/Kivixa-Setup-$version.exe)"
    if ($readmeContent -match $windowsPattern) {
        $readmeContent = $readmeContent -replace $windowsPattern, $windowsReplacement
        $readmeModified = $true
    }

    # Update Android ARM64 download link
    $androidArm64Pattern = '\[!\[Android ARM64\]\([^\)]+\)\]\(https://github\.com/990aa/kivixa/releases/download/[^/]+/Kivixa-Android-[^\)]+arm64[^\)]*\.apk\)'
    $androidArm64Replacement = "[![Android ARM64](https://img.shields.io/badge/Android-ARM64-3DDC84?logo=android&logoColor=white)](https://github.com/990aa/kivixa/releases/download/$tagEncoded/Kivixa-Android-$version-arm64.apk)"
    if ($readmeContent -match $androidArm64Pattern) {
        $readmeContent = $readmeContent -replace $androidArm64Pattern, $androidArm64Replacement
        $readmeModified = $true
    }

    # Update Android ARMv7 download link
    $androidArmv7Pattern = '\[!\[Android ARMv7\]\([^\)]+\)\]\(https://github\.com/990aa/kivixa/releases/download/[^/]+/Kivixa-Android-[^\)]+armv7[^\)]*\.apk\)'
    $androidArmv7Replacement = "[![Android ARMv7](https://img.shields.io/badge/Android-ARMv7-3DDC84?logo=android&logoColor=white)](https://github.com/990aa/kivixa/releases/download/$tagEncoded/Kivixa-Android-$version-armv7.apk)"
    if ($readmeContent -match $androidArmv7Pattern) {
        $readmeContent = $readmeContent -replace $androidArmv7Pattern, $androidArmv7Replacement
        $readmeModified = $true
    }

    # Update Android x86_64 download link
    $androidX64Pattern = '\[!\[Android x86_64\]\([^\)]+\)\]\(https://github\.com/990aa/kivixa/releases/download/[^/]+/Kivixa-Android-[^\)]+x86_64[^\)]*\.apk\)'
    $androidX64Replacement = "[![Android x86_64](https://img.shields.io/badge/Android-x86_64-3DDC84?logo=android&logoColor=white)](https://github.com/990aa/kivixa/releases/download/$tagEncoded/Kivixa-Android-$version-x86_64.apk)"
    if ($readmeContent -match $androidX64Pattern) {
        $readmeContent = $readmeContent -replace $androidX64Pattern, $androidX64Replacement
        $readmeModified = $true
    }

    if ($readmeModified) {
        if (-not $DryRun) {
            $readmeContent | Set-Content $readmeFile -NoNewline
        }
        Write-Host "  [OK] README.md updated with download links for v$version" -ForegroundColor Green
    } else {
        Write-Host "  [SKIP] No matching patterns found in README.md" -ForegroundColor Yellow
    }
} else {
    Write-Host "  [SKIP] README.md not found" -ForegroundColor Yellow
}
Write-Host ""

# ============================================
# Step 4: Verify and collect build artifacts
# ============================================
Write-Host "[4/7] Collecting build artifacts..." -ForegroundColor Yellow

$androidBuildDir = Join-Path $projectRoot "build\app\outputs\flutter-apk"
$windowsBuildDir = Join-Path $projectRoot "build_windows_installer"
$tempReleaseDir = Join-Path $projectRoot "build\release_assets"

# Create temp directory for renamed assets
if (Test-Path $tempReleaseDir) {
    Remove-Item $tempReleaseDir -Recurse -Force
}
New-Item -ItemType Directory -Path $tempReleaseDir -Force | Out-Null

$assets = @()

# Android APKs - rename with version
$androidMappings = @{
    "app-arm64-v8a-release.apk" = "Kivixa-Android-$version-arm64.apk"
    "app-armeabi-v7a-release.apk" = "Kivixa-Android-$version-armv7.apk"
    "app-x86_64-release.apk" = "Kivixa-Android-$version-x86_64.apk"
}

foreach ($mapping in $androidMappings.GetEnumerator()) {
    $sourcePath = Join-Path $androidBuildDir $mapping.Key
    $destPath = Join-Path $tempReleaseDir $mapping.Value
    
    if (Test-Path $sourcePath) {
        if (-not $DryRun) {
            Copy-Item $sourcePath $destPath
        }
        $assets += $destPath
        Write-Host "  [OK] $($mapping.Value)" -ForegroundColor Green
    } else {
        Write-Host "  [MISSING] $($mapping.Key) - run 'flutter build apk --split-per-abi --release' first" -ForegroundColor Red
    }
}

# Windows Installer - find matching version
$windowsInstallerPattern = "Kivixa-Setup-$version.exe"
$windowsInstallerPath = Join-Path $windowsBuildDir $windowsInstallerPattern

if (Test-Path $windowsInstallerPath) {
    $destPath = Join-Path $tempReleaseDir $windowsInstallerPattern
    if (-not $DryRun) {
        Copy-Item $windowsInstallerPath $destPath
    }
    $assets += $destPath
    Write-Host "  [OK] $windowsInstallerPattern" -ForegroundColor Green
} else {
    # Try to find any installer in the directory
    $existingInstallers = Get-ChildItem $windowsBuildDir -Filter "Kivixa-Setup-*.exe" -ErrorAction SilentlyContinue
    if ($existingInstallers) {
        Write-Host "  [MISSING] $windowsInstallerPattern" -ForegroundColor Red
        Write-Host "           Found: $($existingInstallers.Name -join ', ')" -ForegroundColor DarkYellow
        Write-Host "           Please build the Windows installer for version $version" -ForegroundColor DarkYellow
    } else {
        Write-Host "  [MISSING] $windowsInstallerPattern - run Inno Setup compiler first" -ForegroundColor Red
    }
}

Write-Host ""

# Check if we have at least some assets
if ($assets.Count -eq 0) {
    throw "No build artifacts found! Please build the app first."
}

# ============================================
# Step 5: Git operations - commit, tag, push
# ============================================
Write-Host "[5/7] Git operations..." -ForegroundColor Yellow

Push-Location $projectRoot
try {
    # Check for uncommitted changes
    $gitStatus = git status --porcelain
    if ($gitStatus) {
        Write-Host "  Uncommitted changes detected:" -ForegroundColor Yellow
        $gitStatus | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkYellow }
        
        if (-not $DryRun) {
            Write-Host "  Adding and committing changes..." -ForegroundColor Yellow
            git add .
            git commit -m "chore: prepare release v$version"
        } else {
            Write-Host "  [DRY RUN] Would commit changes" -ForegroundColor Magenta
        }
    }
    
    # Check if tag already exists
    $existingTag = git tag -l $tagName
    if ($existingTag) {
        Write-Host "  Tag $tagName already exists" -ForegroundColor Yellow
        $confirm = Read-Host "  Delete and recreate? (y/N)"
        if ($confirm -eq 'y' -or $confirm -eq 'Y') {
            if (-not $DryRun) {
                Write-Host "  Deleting local tag $tagName..." -ForegroundColor Yellow
                git tag -d $tagName
                
                # Check remote tag safely
                $remoteTag = git ls-remote --tags origin $tagName
                if ($remoteTag) {
                    Write-Host "  Deleting remote tag $tagName..." -ForegroundColor Yellow
                    # Run git push in a way that doesn't trigger generic PowerShell errors on stderr output
                    $process = Start-Process -FilePath "git" -ArgumentList "push origin --delete $tagName" -NoNewWindow -Wait -PassThru
                    if ($process.ExitCode -ne 0) {
                        Write-Host "  Warning: Failed to delete remote tag cleanup. Continuing..." -ForegroundColor DarkYellow
                    }
                }
            } else {
                Write-Host "  [DRY RUN] Would delete existing tag" -ForegroundColor Magenta
            }
        } else {
            throw "Tag $tagName already exists. Aborting."
        }
    }
    
    # Create and push tag
    if (-not $DryRun) {
        Write-Host "  Creating tag $tagName..." -ForegroundColor Yellow
        git tag -a $tagName -m "Release $releaseTitle"
        
        Write-Host "  Pushing to origin..." -ForegroundColor Yellow
        git push origin
        git push origin $tagName
    } else {
        Write-Host "  [DRY RUN] Would create tag: $tagName" -ForegroundColor Magenta
        Write-Host "  [DRY RUN] Would push to origin" -ForegroundColor Magenta
    }
    
    Write-Host "  [OK] Git operations complete" -ForegroundColor Green
} finally {
    Pop-Location
}
Write-Host ""

# ============================================
# Step 6: Create GitHub Release
# ============================================
Write-Host "[6/7] Creating GitHub release..." -ForegroundColor Yellow

# Check if gh CLI is installed
$ghVersion = gh --version 2>$null
if (-not $ghVersion) {
    throw "GitHub CLI (gh) is not installed. Install from: https://cli.github.com/"
}

# Check if authenticated
$ghAuth = gh auth status 2>&1
if ($LASTEXITCODE -ne 0) {
    throw "GitHub CLI is not authenticated. Run 'gh auth login' first."
}

# Prepare the release notes file (to handle multiline properly)
$notesFile = Join-Path $tempReleaseDir "release_notes.md"
$releaseNotes | Out-File -FilePath $notesFile -Encoding utf8

# Build the gh release create command
$assetArgs = $assets | Where-Object { Test-Path $_ } | ForEach-Object { "`"$_`"" }
$assetArgsString = $assetArgs -join " "

if (-not $DryRun) {
    Write-Host "  Creating release: $releaseTitle" -ForegroundColor Yellow
    
    # Create the release
    $ghCommand = "gh release create `"$tagName`" --title `"$releaseTitle`" --notes-file `"$notesFile`" $assetArgsString"
    Write-Host "  Command: $ghCommand" -ForegroundColor DarkGray
    
    Invoke-Expression $ghCommand
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  [OK] Release created successfully!" -ForegroundColor Green
    } else {
        throw "Failed to create GitHub release"
    }
} else {
    Write-Host "  [DRY RUN] Would create release:" -ForegroundColor Magenta
    Write-Host "    Title: $releaseTitle" -ForegroundColor Magenta
    Write-Host "    Tag: $tagName" -ForegroundColor Magenta
    Write-Host "    Assets:" -ForegroundColor Magenta
    $assets | ForEach-Object { Write-Host "      - $(Split-Path $_ -Leaf)" -ForegroundColor Magenta }
}
Write-Host ""

# ============================================
# Step 7: Cleanup and Summary
# ============================================
Write-Host "[7/7] Cleanup..." -ForegroundColor Yellow

if (-not $DryRun) {
    # Keep the release assets directory for reference
    Write-Host "  Release assets saved to: $tempReleaseDir" -ForegroundColor Green
} else {
    # Clean up temp directory in dry run
    if (Test-Path $tempReleaseDir) {
        Remove-Item $tempReleaseDir -Recurse -Force
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Release Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Version: $version" -ForegroundColor White
Write-Host "  Tag: $tagName" -ForegroundColor White
Write-Host "  Title: $releaseTitle" -ForegroundColor White
Write-Host ""

if (-not $DryRun) {
    Write-Host "  View release: https://github.com/990aa/kivixa/releases/tag/$tagName" -ForegroundColor Cyan
} else {
    Write-Host "  [DRY RUN] No changes were made" -ForegroundColor Magenta
}
Write-Host ""
