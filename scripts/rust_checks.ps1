# rust_checks.ps1
# Comprehensive Rust quality and security checks
# Runs various cargo tools to ensure code quality

param(
    [Parameter(Position = 0)]
    [string]$CratePath = "",
    
    [switch]$SkipAudit,
    [switch]$SkipDeny,
    [switch]$SkipMiri,
    [switch]$SkipUdeps,
    [switch]$SkipOutdated,
    [switch]$SkipSpellcheck,
    [switch]$QuickCheck  # Only runs check, clippy, fmt, test
)

$ErrorActionPreference = "Continue"
$script:FailedChecks = @()
$script:PassedChecks = @()
$script:SkippedChecks = @()

function Write-Header {
    param([string]$Message)
    Write-Host "`n" -NoNewline
    Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║ " -ForegroundColor Cyan -NoNewline
    $padded = $Message.PadRight(61)
    Write-Host $padded -ForegroundColor White -NoNewline
    Write-Host " ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
}

function Write-Check {
    param([string]$Message)
    Write-Host "`n▶ " -ForegroundColor Yellow -NoNewline
    Write-Host $Message -ForegroundColor Yellow
    Write-Host ("─" * 65) -ForegroundColor DarkGray
}

function Write-Success {
    param([string]$Message)
    Write-Host "  ✓ " -ForegroundColor Green -NoNewline
    Write-Host $Message -ForegroundColor Green
}

function Write-Failure {
    param([string]$Message)
    Write-Host "  ✗ " -ForegroundColor Red -NoNewline
    Write-Host $Message -ForegroundColor Red
}

function Write-Skip {
    param([string]$Message)
    Write-Host "  ⊘ " -ForegroundColor DarkYellow -NoNewline
    Write-Host $Message -ForegroundColor DarkYellow
}

function Write-Info {
    param([string]$Message)
    Write-Host "  ℹ " -ForegroundColor Blue -NoNewline
    Write-Host $Message -ForegroundColor Gray
}

function Test-CommandExists {
    param([string]$Command)
    $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

function Run-Check {
    param(
        [string]$Name,
        [string]$Command,
        [string[]]$Arguments,
        [switch]$Optional,
        [switch]$Skip
    )
    
    Write-Check $Name
    
    if ($Skip) {
        Write-Skip "$Name skipped (flag set)"
        $script:SkippedChecks += $Name
        return
    }
    
    if (-not (Test-CommandExists $Command)) {
        if ($Optional) {
            Write-Skip "$Command not installed - skipping (optional)"
            $script:SkippedChecks += $Name
        } else {
            Write-Failure "$Command not found - please install it"
            $script:FailedChecks += $Name
        }
        return
    }
    
    Write-Info "Running: $Command $($Arguments -join ' ')"
    
    & $Command @Arguments 2>&1 | ForEach-Object { Write-Host "    $_" }
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "$Name passed"
        $script:PassedChecks += $Name
    } else {
        Write-Failure "$Name failed (exit code: $LASTEXITCODE)"
        $script:FailedChecks += $Name
    }
}

# Determine crate path
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir

if ($CratePath -eq "") {
    Write-Host "Usage: .\rust_checks.ps1 <crate_path>" -ForegroundColor Yellow
    Write-Host "Available crates:" -ForegroundColor Gray
    
    $nativeMath = Join-Path $projectRoot "native_math"
    $native = Join-Path $projectRoot "native"
    
    if (Test-Path $nativeMath) {
        Write-Host "  - native_math (math library)" -ForegroundColor Gray
    }
    if (Test-Path $native) {
        Write-Host "  - native (AI inference library)" -ForegroundColor Gray
    }
    
    Write-Host "`nExample: .\rust_checks.ps1 native_math" -ForegroundColor Gray
    exit 1
}

# Resolve crate path
if ([System.IO.Path]::IsPathRooted($CratePath)) {
    $targetDir = $CratePath
} else {
    $targetDir = Join-Path $projectRoot $CratePath
}

if (-not (Test-Path $targetDir)) {
    Write-Host "Error: Crate directory not found: $targetDir" -ForegroundColor Red
    exit 1
}

$cargoToml = Join-Path $targetDir "Cargo.toml"
if (-not (Test-Path $cargoToml)) {
    Write-Host "Error: No Cargo.toml found in $targetDir" -ForegroundColor Red
    exit 1
}

# Read crate name from Cargo.toml
$crateName = $CratePath
$cargoContent = Get-Content $cargoToml -Raw
if ($cargoContent -match 'name\s*=\s*"([^"]+)"') {
    $crateName = $Matches[1]
}

Write-Header "Rust Quality Checks: $crateName"
Write-Host "Crate path: $targetDir" -ForegroundColor Gray
Write-Host "Started at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray

# Change to crate directory
Push-Location $targetDir

try {
    # ═══════════════════════════════════════════════════════════════
    # CORE CHECKS (always run)
    # ═══════════════════════════════════════════════════════════════
    
    # 1. cargo check - Type checking
    Run-Check -Name "Type Check (cargo check)" `
              -Command "cargo" `
              -Arguments @("check", "--all-targets", "--all-features")
    
    # 2. cargo clippy - Linting
    Run-Check -Name "Clippy Lints (cargo clippy)" `
              -Command "cargo" `
              -Arguments @("clippy", "--all-targets", "--all-features", "--", "-D", "warnings")
    
    # 3. cargo fmt - Formatting check
    Run-Check -Name "Format Check (cargo fmt)" `
              -Command "cargo" `
              -Arguments @("fmt", "--all", "--", "--check")
    
    # 4. cargo test - Unit tests
    Run-Check -Name "Unit Tests (cargo test)" `
              -Command "cargo" `
              -Arguments @("test", "--all-features")
    
    if ($QuickCheck) {
        Write-Host "`n⚡ Quick check mode - skipping additional tools" -ForegroundColor DarkYellow
    } else {
        # ═══════════════════════════════════════════════════════════════
        # DEPENDENCY CHECKS
        # ═══════════════════════════════════════════════════════════════
        
        # 5. cargo update - Check for dependency updates (dry run)
        Run-Check -Name "Dependency Update Check (cargo update)" `
                  -Command "cargo" `
                  -Arguments @("update", "--dry-run")
        
        # 6. cargo audit - Security vulnerability check
        Run-Check -Name "Security Audit (cargo audit)" `
                  -Command "cargo" `
                  -Arguments @("audit") `
                  -Optional `
                  -Skip:$SkipAudit
        
        # 7. cargo deny - License and dependency policy check
        Run-Check -Name "Dependency Policy (cargo deny)" `
                  -Command "cargo" `
                  -Arguments @("deny", "check") `
                  -Optional `
                  -Skip:$SkipDeny
        
        # 8. cargo outdated - Check for outdated dependencies
        Run-Check -Name "Outdated Dependencies (cargo outdated)" `
                  -Command "cargo" `
                  -Arguments @("outdated", "--root-deps-only") `
                  -Optional `
                  -Skip:$SkipOutdated
        
        # 9. cargo udeps - Find unused dependencies
        Run-Check -Name "Unused Dependencies (cargo udeps)" `
                  -Command "cargo" `
                  -Arguments @("+nightly", "udeps", "--all-targets") `
                  -Optional `
                  -Skip:$SkipUdeps
        
        # ═══════════════════════════════════════════════════════════════
        # ADVANCED CHECKS (may require nightly or additional setup)
        # ═══════════════════════════════════════════════════════════════
        
        # 10. cargo miri - Undefined behavior detection
        Write-Check "Memory Safety (cargo miri)"
        if ($SkipMiri) {
            Write-Skip "Miri skipped (flag set)"
            $script:SkippedChecks += "Memory Safety (cargo miri)"
        } else {
            # Check if miri is available
            $miriAvailable = $false
            try {
                cargo +nightly miri --version 2>$null
                if ($LASTEXITCODE -eq 0) {
                    $miriAvailable = $true
                }
            } catch {}
            
            if ($miriAvailable) {
                Write-Info "Running: cargo +nightly miri test"
                cargo +nightly miri test 2>&1 | ForEach-Object { Write-Host "    $_" }
                if ($LASTEXITCODE -eq 0) {
                    Write-Success "Memory Safety (cargo miri) passed"
                    $script:PassedChecks += "Memory Safety (cargo miri)"
                } else {
                    Write-Failure "Memory Safety (cargo miri) failed"
                    $script:FailedChecks += "Memory Safety (cargo miri)"
                }
            } else {
                Write-Skip "Miri not installed - skipping (requires: rustup +nightly component add miri)"
                $script:SkippedChecks += "Memory Safety (cargo miri)"
            }
        }
        
    
        # 11. cargo spellcheck - Documentation spell checking
        Run-Check -Name "Documentation Spellcheck (cargo spellcheck)" `
                  -Command "cargo" `
                  -Arguments @("spellcheck", "check") `
                  -Optional `
                  -Skip:$SkipSpellcheck
    }
    
    # ═══════════════════════════════════════════════════════════════
    # SUMMARY
    # ═══════════════════════════════════════════════════════════════
    
    Write-Header "Check Summary"
    
    Write-Host "`nPassed Checks ($($script:PassedChecks.Count)):" -ForegroundColor Green
    foreach ($check in $script:PassedChecks) {
        Write-Host "  ✓ $check" -ForegroundColor Green
    }
    
    if ($script:SkippedChecks.Count -gt 0) {
        Write-Host "`nSkipped Checks ($($script:SkippedChecks.Count)):" -ForegroundColor DarkYellow
        foreach ($check in $script:SkippedChecks) {
            Write-Host "  ⊘ $check" -ForegroundColor DarkYellow
        }
    }
    
    if ($script:FailedChecks.Count -gt 0) {
        Write-Host "`nFailed Checks ($($script:FailedChecks.Count)):" -ForegroundColor Red
        foreach ($check in $script:FailedChecks) {
            Write-Host "  ✗ $check" -ForegroundColor Red
        }
    }
    
    Write-Host "`n" -NoNewline
    Write-Host ("═" * 65) -ForegroundColor Cyan
    
    $total = $script:PassedChecks.Count + $script:FailedChecks.Count + $script:SkippedChecks.Count
    Write-Host "Total: $total | " -NoNewline
    Write-Host "Passed: $($script:PassedChecks.Count)" -ForegroundColor Green -NoNewline
    Write-Host " | " -NoNewline
    Write-Host "Failed: $($script:FailedChecks.Count)" -ForegroundColor Red -NoNewline
    Write-Host " | " -NoNewline
    Write-Host "Skipped: $($script:SkippedChecks.Count)" -ForegroundColor DarkYellow
    
    Write-Host "Completed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
    Write-Host ("═" * 65) -ForegroundColor Cyan
    
    if ($script:FailedChecks.Count -gt 0) {
        Write-Host "`n⚠ Some checks failed. Please review the output above." -ForegroundColor Red
        exit 1
    } else {
        Write-Host "`n✓ All checks passed successfully!" -ForegroundColor Green
        exit 0
    }
}
finally {
    Pop-Location
}
