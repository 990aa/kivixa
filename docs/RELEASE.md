# Kivixa Release Process

This document describes how to release new versions of Kivixa.

## Overview

Kivixa uses a fully automated CI/CD pipeline powered by GitHub Actions. When you push a version tag (e.g., `v0.1.7+1007`), the workflow automatically:

1. **Builds Android APKs** (ARM64, ARMv7, x86_64) with Rust native libraries
2. **Builds Windows Installer** with code signing and Rust native libraries
3. **Creates a GitHub Release** with all artifacts
4. **Updates F-Droid repository** on gh-pages
5. **Updates README.md** download links

## Prerequisites

Before releasing, ensure these GitHub Secrets are configured:

| Secret | Description |
|--------|-------------|
| `ANDROID_KEYSTORE_BASE64` | Base64-encoded Android keystore file |
| `ANDROID_KEY_ALIAS` | Android key alias |
| `ANDROID_KEY_PASSWORD` | Android key password |
| `WINDOWS_CERT_BASE64` | Base64-encoded Windows PFX certificate |
| `WINDOWS_CERT_PASSWORD` | Windows certificate password |

## Quick Release (Recommended)

Use the one-click release script:

```powershell
# Release current version (from VERSION file)
.\scripts\release.ps1

# Release with patch bump (0.1.6 → 0.1.7)
.\scripts\release.ps1 -BumpPatch

# Release with minor bump (0.1.6 → 0.2.0)
.\scripts\release.ps1 -BumpMinor

# Preview without executing
.\scripts\release.ps1 -DryRun
```

## Manual Release

### Step 1: Update Version

1. Edit `VERSION` file with new version (e.g., `0.1.7+1007`)
2. Update `pubspec.yaml` version to match
3. Update `CHANGELOG.md` with release notes

### Step 2: Commit Changes

```bash
git add VERSION pubspec.yaml CHANGELOG.md
git commit -m "chore: bump version to 0.1.7+1007"
git push origin main
```

### Step 3: Create and Push Tag

```bash
git tag v0.1.7+1007 -m "Release v0.1.7+1007"
git push origin v0.1.7+1007
```

### Step 4: Monitor Workflow

1. Go to [GitHub Actions](https://github.com/990aa/kivixa/actions)
2. Watch the "Build and Release" workflow
3. Verify all jobs complete successfully

## Testing the Workflow

### Method 1: Test Tag

Push a test tag that will be marked as prerelease:

```powershell
git tag v0.0.1-test -m "Test release workflow"
git push origin v0.0.1-test
```

> **Note:** Test releases are automatically marked as prereleases and won't update README links.

### Method 2: Manual Trigger (workflow_dispatch)

1. Go to [Actions → Build and Release](https://github.com/990aa/kivixa/actions/workflows/release.yml)
2. Click "Run workflow"
3. Fill in test parameters:
   - `test_version`: `0.0.1-test`
   - `skip_release`: ✓ (checked)
   - `skip_fdroid`: ✓ (checked)
4. Click "Run workflow"

This tests the build process without creating releases.

## Cleaning Up Test Releases

After testing, clean up:

```bash
# Delete local tag
git tag -d v0.0.1-test

# Delete remote tag
git push origin --delete v0.0.1-test

# Delete the draft/prerelease from GitHub Releases page
```

## Version Format

Kivixa uses semantic versioning with build numbers:

```
v{MAJOR}.{MINOR}.{PATCH}+{BUILD}
```

## Artifact Naming

| Platform | Artifact |
|----------|----------|
| Windows | `Kivixa-Setup-{VERSION}.exe` |
| Android ARM64 | `Kivixa-Android-{VERSION}-arm64.apk` |
| Android ARMv7 | `Kivixa-Android-{VERSION}-armv7.apk` |
| Android x86_64 | `Kivixa-Android-{VERSION}-x86_64.apk` |

## F-Droid Repository

The F-Droid repository is automatically updated on the `gh-pages` branch. Users can add:

```
https://990aa.github.io/kivixa/repo
```

## Auto-Update System

The Windows app has a built-in update checker (`UpdateManager`) that:
- Checks GitHub Releases API on startup
- Compares current version with latest release
- Notifies users of available updates
- Provides download links

## Troubleshooting

### Build Fails: Rust Native Libraries

If Rust compilation fails:
1. Check that `native/` and `native_math/` directories have valid Cargo.toml
2. Ensure Rust targets are correctly specified in workflow
3. Verify NDK version (r26b) for Android builds

### Build Fails: Android Signing

1. Verify `ANDROID_KEYSTORE_BASE64` is valid base64
2. Check `ANDROID_KEY_ALIAS` matches the keystore
3. Ensure passwords are correct

### Build Fails: Windows Signing

1. Verify `WINDOWS_CERT_BASE64` is valid base64
2. Check `WINDOWS_CERT_PASSWORD` is correct
3. Note: Signing failures use `continue-on-error` - builds will succeed unsigned

### F-Droid Update Fails

1. Ensure `gh-pages` branch exists
2. Check fdroidserver is installing correctly
3. Verify APK signatures
