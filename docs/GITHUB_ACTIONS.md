# GitHub Actions Guide for Kivixa

This guide explains how to use the GitHub Actions workflows for automated builds and releases.

## Workflows

### 1. Build Windows (`build-windows.yml`)

Builds the Windows application with the Rust native library.

**Triggers:**
- Push to `main` branch (when relevant files change)
- Manual dispatch via GitHub UI
- Called by release workflow

**What it does:**
1. Sets up Flutter and Rust toolchains
2. Builds the Rust native library (`kivixa_native.dll`)
3. Builds the Flutter Windows app
4. Bundles the DLL with the app
5. Uploads the release folder as an artifact

---

### 2. Build Android (`build-android.yml`)

Cross-compiles Rust for Android and builds the APK.

**Triggers:**
- Push to `main` branch (when relevant files change)
- Manual dispatch via GitHub UI
- Called by release workflow

**What it does:**
1. Sets up Flutter, Java, Rust, and Android NDK
2. Uses `cargo-ndk` to cross-compile Rust for:
   - `arm64-v8a` (modern 64-bit Android devices)
   - `armeabi-v7a` (older 32-bit Android devices)
   - `x86_64` (emulators)
3. Places compiled `.so` files in `jniLibs`
4. Builds the Flutter APK
5. Uploads the APK as an artifact

---

### 3. Release (`release.yml`)

Creates a GitHub Release with all platform builds.

**Triggers:**
- Push a tag starting with `v` (e.g., `v0.1.0`)
- Manual dispatch with version input

**What it does:**
1. Calls both build workflows
2. Downloads all artifacts
3. Creates a ZIP for Windows
4. Creates a GitHub Release with:
   - Changelog from `metadata/en-US/changelogs/`
   - Windows ZIP file
   - Android APK

---

## How to Create a Release

### Option 1: Using Git Tags (Recommended)

```bash
# 1. Update version in pubspec.yaml and lib/data/version.dart
# 2. Create and push a tag
git tag v0.1.1
git push origin v0.1.1
```

The release workflow will automatically:
- Build Windows and Android versions
- Create a GitHub Release with the artifacts

### Option 2: Manual Dispatch

1. Go to **Actions** tab in GitHub
2. Select **Release** workflow
3. Click **Run workflow**
4. Enter the version tag (e.g., `v0.1.1`)
5. Click **Run workflow**

---

## Version Management

Before releasing:

1. Update `VERSION` file:
   ```
   MAJOR=0
   MINOR=1
   PATCH=1
   BUILD_NUMBER=2
   ```

2. Run the bump script (if available):
   ```bash
   dart run scripts/bump_version.dart
   ```

3. Add changelog at `metadata/en-US/changelogs/<BUILD_NUMBER>.txt`

---

## Troubleshooting

### Rust Build Fails

- Ensure `native/Cargo.toml` compiles locally
- Check NDK version matches `ndk-version: r26d`

### Android Build Fails

- Verify Java 17 is required
- Check that `minSdk` is 21 or higher

### Windows Build Fails

- Ensure MSVC toolchain is used
- Check Flutter Windows dependencies

---

## Artifacts

Build artifacts are retained for 30 days. Download from:
- **Actions** → Select a workflow run → **Artifacts** section
