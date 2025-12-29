# Release Instructions for Kivixa

## Prerequisites

1.  **Flutter SDK**: [Install Flutter](https://flutter.dev/docs/get-started/install)
2.  **Rust Toolchain**: [Install Rust](https://www.rust-lang.org/tools/install)
3.  **Inno Setup Compiler**: [Install Inno Setup](https://jrsoftware.org/isdl.php) (Required for Windows Installer)
4.  **GitHub CLI (`gh`)**: [Install GitHub CLI](https://cli.github.com/) (Optional but recommended)
5.  **Git**: [Install Git](https://git-scm.com/)

## Step 1: Bump Version

Before building, you must update the version number across the project.

1.  Open a terminal in the project root.
2.  Run the bump version script:

    ```powershell
    # Bump patch version (e.g., 0.1.0 -> 0.1.1)
    dart run scripts/bump_version.dart --patch

    # OR Bump minor version (e.g., 0.1.0 -> 0.2.0)
    dart run scripts/bump_version.dart --minor

    # OR Set a specific version
    dart run scripts/bump_version.dart --set 1.0.0
    ```

    This script automatically updates:
    *   `VERSION`
    *   `pubspec.yaml`
    *   `lib/data/version.dart`
    *   `lib/services/terms_and_conditions_service.dart`
    *   `test/samples/github_releases_api.json`
    *   `android/app/build.gradle.kts`
    *   `ios/Runner/Info.plist`
    *   `windows/runner/Runner.rc`

3.  Verify the changes and commit them:

    ```bash
    git add .
    git commit -m "chore: bump version to X.Y.Z"
    ```

## Step 2: Build Native Libraries

Kivixa uses Rust for some core functionality. You need to build the native libraries before building the Flutter app.

1.  Run the native build script:

    ```powershell
    ./scripts/build_native.ps1
    ```

    This script will:
    *   Compile the Rust code for Windows (`.dll`).
    *   Compile the Rust code for Android (`.so` for arm64 and armv7).
    *   Copy the compiled libraries to the appropriate Flutter directories.

    *Note: Ensure you have Android NDK installed and configured for Rust cross-compilation if building for Android.*

## Step 3: Build for Android

To create APKs for all supported architectures (ARM64, ARMv7, x86_64):

1.  Run the Flutter build command:

    ```bash
    flutter build apk --split-per-abi --release --obfuscate -v
    ```

    This will generate three APK files in `build/app/outputs/flutter-apk/`:
    *   `app-armeabi-v7a-release.apk` (Older Android devices)
    *   `app-arm64-v8a-release.apk` (Modern Android devices)
    *   `app-x86_64-release.apk` (Emulators)

    *Note: If you want a single "fat" APK that works on all devices (larger file size), run `flutter build apk --release` instead.*

## Step 4: Build for Windows

1.  Build the Flutter Windows application:

    ```bash
    flutter build windows --release --obfuscate -v
    ```

2.  Create the Installer using Inno Setup:
    *   Open `windows/installer/kivixa-installer.iss` with Inno Setup Compiler.
    *   Click **Build** > **Compile** (or press `Ctrl+F9`).
    *   The installer executable (e.g., `Kivixa-Setup-X.Y.Z.exe`) will be generated in the `build_windows_installer/` directory (or wherever `OutputDir` is configured in the `.iss` file).

## Step 5: Create GitHub Release

You can create the release using the GitHub CLI (`gh`) or manually via the website.

### Option A: Using GitHub CLI (Recommended)

1.  Create a tag and push it:

    ```bash
    git tag vX.Y.Z
    git push origin vX.Y.Z
    ```

2.  Create the release and upload assets:

    ```bash
    # Replace X.Y.Z with your version
    # Replace paths to assets if they differ
    gh release create vX.Y.Z `
        --title "Kivixa vX.Y.Z" `
        --notes "Release notes here..." `
        windows/installer/Output/Kivixa-Setup-X.Y.Z.exe `
        build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk `
        build/app/outputs/flutter-apk/app-arm64-v8a-release.apk `
        build/app/outputs/flutter-apk/app-x86_64-release.apk
    ```

### Option B: Using GitHub Actions (Automated)

If you have the GitHub Actions workflow configured (`.github/workflows/release.yml`), you can simply push the tag, and it will build and release automatically.

1.  Tag and push:
    ```bash
    git tag vX.Y.Z
    git push origin vX.Y.Z
    ```

2.  Wait for the Action to complete.
    *   Note: The default Action might only create a ZIP for Windows. If you want the Installer, you might need to update the workflow or upload the Installer manually after the Action finishes.

### Option C: Manual Website Upload

1.  Tag and push:
    ```bash
    git tag vX.Y.Z
    git push origin vX.Y.Z
    ```
2.  Go to the [Releases page](https://github.com/990aa/kivixa/releases) on GitHub.
3.  Click "Draft a new release".
4.  Choose the tag `vX.Y.Z`.
5.  Fill in the title and description.
6.  Drag and drop the generated files:
    *   `Kivixa-Setup-X.Y.Z.exe`
    *   `app-armeabi-v7a-release.apk`
    *   `app-arm64-v8a-release.apk`
    *   `app-x86_64-release.apk`
7.  Click "Publish release".

## Summary Checklist

- [ ] `dart run scripts/bump_version.dart ...`
- [ ] `git commit` version bump
- [ ] `./scripts/build_native.ps1`
- [ ] `flutter build apk --split-per-abi --release`
- [ ] `flutter build windows --release`
- [ ] Compile `windows/installer/kivixa-installer.iss`
- [ ] `git tag vX.Y.Z` & `git push`
- [ ] Upload assets to GitHub Release
