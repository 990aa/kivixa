# Distribution Guide

This guide provides detailed steps for building and distributing Kivixa application files for all supported platforms.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Windows Distribution](#windows-distribution)
- [Android Distribution](#android-distribution)
- [Web Distribution](#web-distribution)
- [iOS Distribution](#ios-distribution-macos-host-required)
- [macOS Distribution](#macos-distribution-macos-host-required)
- [Linux Distribution](#linux-distribution-linux-host-required)
- [GitHub Releases](#publishing-to-github-releases)

---

## Prerequisites

### General Requirements

1. **Flutter SDK**: Ensure Flutter is installed and on your PATH
   ```bash
   flutter --version
   ```

2. **Dependencies**: Install all project dependencies
   ```bash
   flutter pub get
   ```

3. **Testing**: Test the app before building
   ```bash
   flutter test
   flutter analyze
   ```

---

## Windows Distribution

### Requirements
- Windows 10 or later
- Visual Studio 2022 or later (with "Desktop development with C++" workload)

### Build Steps

1. **Clean previous builds** (optional but recommended):
   ```powershell
   flutter clean
   flutter pub get
   ```

2. **Build Windows release executable**:
   ```powershell
   flutter build windows --release
   ```

3. **Locate the build output**:
   - Path: `build\windows\x64\runner\Release\`
   - Main executable: `kivixa.exe`
   - Required files in the same directory:
     - All `.dll` files (flutter_windows.dll, etc.)
     - `data/` folder (contains app resources)

### Distribution Package

Create a distribution folder with:
```
kivixa-windows/
├── kivixa.exe
├── flutter_windows.dll
├── [other .dll files]
└── data/
    ├── icudtl.dat
    ├── flutter_assets/
    └── [other resources]
```

**Important**: All files in the `Release` folder must be distributed together. Users cannot run just the `.exe` file alone.

### Optional: Create Installer

For a professional installer, consider using:
- **Inno Setup**: Free, simple Windows installer creator
- **NSIS**: Nullsoft Scriptable Install System
- **WiX Toolset**: Advanced Windows installer XML toolkit

### Testing

Test on a clean Windows machine without Flutter SDK installed to ensure all dependencies are included.

---

## Android Distribution

### Requirements
- Android Studio with Android SDK
- Java JDK 11 or later
- For Play Store: A Google Play Developer account ($25 one-time fee)

### Build Steps

#### 1. Configure App Signing (for release builds)

Create a keystore (one-time setup):
```bash
keytool -genkey -v -keystore C:\Users\<username>\upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Create `android/key.properties`:
```properties
storePassword=<password>
keyPassword=<password>
keyAlias=upload
storeFile=C:\\Users\\<username>\\upload-keystore.jks
```

**Important**: Add `key.properties` to `.gitignore` (never commit this file!)

Update `android/app/build.gradle.kts`:
```kotlin
// Add before android block
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    // ... existing config ...
    
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String
        }
    }
    
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

#### 2. Build APK (for direct distribution)

```bash
flutter build apk --release
```

Output: `build\app\outputs\flutter-apk\app-release.apk` (~63 MB)

**APK distribution**: Users can install directly on Android devices (may need to enable "Install from Unknown Sources")

#### 3. Build App Bundle (for Google Play Store)

```bash
flutter build appbundle --release
```

Output: `build\app\outputs\bundle\release\app-release.aab`

**App Bundle benefits**:
- Smaller download size (Google Play optimizes per-device)
- Required for Google Play Store uploads
- Better for users with different device configurations

#### 4. Build Split APKs (for multiple architectures)

```bash
flutter build apk --split-per-abi --release
```

Outputs (in `build\app\outputs\flutter-apk\`):
- `app-armeabi-v7a-release.apk` (32-bit ARM)
- `app-arm64-v8a-release.apk` (64-bit ARM - most common)
- `app-x86_64-release.apk` (64-bit Intel/AMD)

### Version Management

Update version in `pubspec.yaml`:
```yaml
version: 1.0.0+1  # format: major.minor.patch+buildNumber
```

For each release, increment the build number (the number after `+`):
- `1.0.0+1` → `1.0.0+2` (same version, new build)
- `1.0.0+2` → `1.0.1+3` (patch update)
- `1.0.1+3` → `1.1.0+4` (minor update)
- `1.1.0+4` → `2.0.0+5` (major update)

### Publishing to Google Play Store

1. **Create a Google Play Console account**: https://play.google.com/console
2. **Create a new app** in the Console
3. **Upload the App Bundle** (`.aab` file)
4. **Complete store listing**: screenshots, description, privacy policy, etc.
5. **Submit for review**

### Testing

Test APK on physical devices or emulators:
```bash
flutter install --release
# or
adb install build\app\outputs\flutter-apk\app-release.apk
```

---

## Web Distribution

### Requirements
- Any OS with Flutter SDK
- Web server for hosting (or use GitHub Pages, Firebase Hosting, Netlify, etc.)

### Build Steps

1. **Build web release**:
   ```bash
   flutter build web --release
   ```

2. **Optimize for production** (optional):
   ```bash
   flutter build web --release --web-renderer canvaskit
   # or for better initial load
   flutter build web --release --web-renderer html
   ```

3. **Locate build output**:
   - Path: `build\web\`
   - Contents: `index.html`, `main.dart.js`, `assets/`, etc.

### Deployment Options

#### GitHub Pages

1. Create a `.github/workflows/web-deploy.yml`:
```yaml
name: Deploy to GitHub Pages

on:
  push:
    branches: [ main ]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.35.4'
      
      - run: flutter pub get
      - run: flutter build web --release
      
      - uses: actions/upload-pages-artifact@v2
        with:
          path: 'build/web'
      
      - uses: actions/deploy-pages@v2
```

2. Enable GitHub Pages in repository settings
3. Set source to "GitHub Actions"

#### Firebase Hosting

1. Install Firebase CLI:
   ```bash
   npm install -g firebase-tools
   ```

2. Initialize Firebase:
   ```bash
   firebase login
   firebase init hosting
   ```

3. Configure `firebase.json`:
   ```json
   {
     "hosting": {
       "public": "build/web",
       "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
       "rewrites": [
         {
           "source": "**",
           "destination": "/index.html"
         }
       ]
     }
   }
   ```

4. Deploy:
   ```bash
   firebase deploy
   ```

#### Netlify

1. Install Netlify CLI:
   ```bash
   npm install -g netlify-cli
   ```

2. Deploy:
   ```bash
   netlify deploy --prod --dir=build/web
   ```

Or simply drag and drop the `build/web` folder to https://app.netlify.com/drop

### Testing

Test locally before deployment:
```bash
cd build\web
python -m http.server 8000
# or with Node.js
npx http-server
```

Visit: http://localhost:8000

---

## iOS Distribution (macOS Host Required)

### Requirements
- **macOS** (Monterey 12 or later)
- Xcode 14 or later
- Apple Developer account ($99/year for App Store distribution)
- CocoaPods: `sudo gem install cocoapods`

### Build Steps

#### 1. iOS Setup (one-time)

```bash
# On macOS
cd ios
pod install
cd ..
```

#### 2. Configure Signing

Open `ios/Runner.xcworkspace` in Xcode:
1. Select "Runner" in the project navigator
2. Select "Signing & Capabilities" tab
3. Set your Team (requires Apple Developer account)
4. Set a unique Bundle Identifier (e.g., `com.yourname.kivixa`)

#### 3. Update App Information

Edit `ios/Runner/Info.plist`:
```xml
<key>CFBundleDisplayName</key>
<string>Kivixa</string>
<key>CFBundleShortVersionString</key>
<string>1.0.0</string>
<key>CFBundleVersion</key>
<string>1</string>
```

#### 4. Build IPA (for App Store or TestFlight)

```bash
flutter build ipa --release
```

Output: `build/ios/ipa/kivixa.ipa`

#### 5. Build for Simulator (for testing)

```bash
flutter build ios --release --simulator
```

### Distribution Options

#### App Store

1. Open Xcode, select "Product" > "Archive"
2. Once archived, click "Distribute App"
3. Choose "App Store Connect"
4. Follow prompts to upload

Or use the command line:
```bash
xcrun altool --upload-app --type ios --file build/ios/ipa/kivixa.ipa --username "your@email.com" --password "app-specific-password"
```

#### TestFlight (Beta Testing)

1. Upload IPA to App Store Connect
2. Configure TestFlight settings
3. Invite beta testers via email

#### Ad Hoc Distribution

For internal distribution without the App Store:
1. Register device UDIDs in Apple Developer portal
2. Create Ad Hoc provisioning profile
3. Build with Ad Hoc profile
4. Distribute IPA file to registered devices

### Testing

```bash
# Run on simulator
flutter run --release -d "iPhone 15 Pro"

# Run on physical device
flutter run --release -d <device-id>
```

---

## macOS Distribution (macOS Host Required)

### Requirements
- **macOS** (Monterey 12 or later)
- Xcode 14 or later
- Apple Developer account (for distribution outside Mac App Store: $99/year)

### Build Steps

#### 1. Build macOS App

```bash
flutter build macos --release
```

Output: `build/macos/Build/Products/Release/kivixa.app`

#### 2. Test the App

```bash
open build/macos/Build/Products/Release/kivixa.app
```

### Distribution Options

#### Direct Distribution (requires signing)

1. **Sign the app** (requires Apple Developer account):
   ```bash
   codesign --force --deep --sign "Developer ID Application: Your Name (TEAM_ID)" build/macos/Build/Products/Release/kivixa.app
   ```

2. **Notarize the app** (required for macOS 10.15+):
   ```bash
   ditto -c -k --keepParent build/macos/Build/Products/Release/kivixa.app kivixa.zip
   xcrun notarytool submit kivixa.zip --apple-id "your@email.com" --password "app-specific-password" --team-id "TEAM_ID" --wait
   ```

3. **Staple the notarization**:
   ```bash
   xcrun stapler staple build/macos/Build/Products/Release/kivixa.app
   ```

4. **Create DMG** (optional, for easier distribution):
   ```bash
   hdiutil create -volname "Kivixa" -srcfolder build/macos/Build/Products/Release/kivixa.app -ov -format UDZO kivixa.dmg
   ```

#### Mac App Store

1. Configure in Xcode
2. Build and archive
3. Upload to App Store Connect
4. Submit for review

### Unsigned Distribution (for development only)

For personal use or trusted users, you can distribute the unsigned `.app` file. Users will need to:
1. Right-click the app
2. Select "Open"
3. Confirm security warning

---

## Linux Distribution (Linux Host Required)

### Requirements
- **Linux** (Ubuntu 20.04+ or equivalent)
- CMake, Ninja, Clang
- GTK 3 development libraries

Install dependencies (Ubuntu/Debian):
```bash
sudo apt-get update
sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-12-dev
```

### Build Steps

1. **Build Linux release**:
   ```bash
   flutter build linux --release
   ```

2. **Locate build output**:
   - Path: `build/linux/x64/release/bundle/`
   - Contents: `kivixa` (executable) and `lib/`, `data/` folders

### Distribution Package

The entire `bundle/` folder must be distributed together:
```
kivixa-linux/
├── kivixa (executable)
├── lib/
│   └── [shared libraries]
└── data/
    └── [app resources]
```

### Create Distributable Package

#### AppImage (recommended)

1. Install `appimagetool`:
   ```bash
   wget https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
   chmod +x appimagetool-x86_64.AppImage
   ```

2. Create AppDir structure:
   ```bash
   mkdir -p kivixa.AppDir/usr/bin
   cp -r build/linux/x64/release/bundle/* kivixa.AppDir/usr/bin/
   ```

3. Create `.desktop` file (`kivixa.AppDir/kivixa.desktop`):
   ```ini
   [Desktop Entry]
   Name=Kivixa
   Exec=kivixa
   Icon=kivixa
   Type=Application
   Categories=Utility;Office;
   ```

4. Add icon (if available):
   ```bash
   cp icon.png kivixa.AppDir/kivixa.png
   ```

5. Build AppImage:
   ```bash
   ./appimagetool-x86_64.AppImage kivixa.AppDir kivixa-x86_64.AppImage
   ```

#### Snap Package

1. Create `snap/snapcraft.yaml`:
   ```yaml
   name: kivixa
   version: '1.0.0'
   summary: PDF Annotation Tool
   description: |
     Kivixa is a powerful PDF viewer and annotation tool.
   
   grade: stable
   confinement: strict
   base: core22
   
   apps:
     kivixa:
       command: kivixa
       plugs: [home, network]
   
   parts:
     kivixa:
       plugin: dump
       source: build/linux/x64/release/bundle/
   ```

2. Build snap:
   ```bash
   snapcraft
   ```

#### Flatpak

Requires more complex setup. Refer to: https://docs.flatpak.org/en/latest/first-build.html

#### Debian Package (.deb)

1. Create package structure:
   ```bash
   mkdir -p kivixa-deb/DEBIAN
   mkdir -p kivixa-deb/opt/kivixa
   cp -r build/linux/x64/release/bundle/* kivixa-deb/opt/kivixa/
   ```

2. Create control file (`kivixa-deb/DEBIAN/control`):
   ```
   Package: kivixa
   Version: 1.0.0
   Section: utils
   Priority: optional
   Architecture: amd64
   Maintainer: Your Name <your@email.com>
   Description: PDF Annotation Tool
    Kivixa is a powerful PDF viewer and annotation tool.
   ```

3. Build package:
   ```bash
   dpkg-deb --build kivixa-deb
   ```

### Testing

```bash
./build/linux/x64/release/bundle/kivixa
```

---

## Publishing to GitHub Releases

### Automated Release with GitHub Actions

Create `.github/workflows/release.yml`:

```yaml
name: Build and Release

on:
  push:
    tags:
      - 'v*'

jobs:
  build-windows:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.35.4'
      - run: flutter pub get
      - run: flutter build windows --release
      - name: Compress Windows Build
        run: Compress-Archive -Path build\windows\x64\runner\Release\* -DestinationPath kivixa-windows.zip
      - uses: actions/upload-artifact@v3
        with:
          name: windows-build
          path: kivixa-windows.zip

  build-android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v3
        with:
          distribution: 'zulu'
          java-version: '17'
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.35.4'
      - run: flutter pub get
      - run: flutter build apk --release
      - uses: actions/upload-artifact@v3
        with:
          name: android-apk
          path: build/app/outputs/flutter-apk/app-release.apk

  build-web:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.35.4'
      - run: flutter pub get
      - run: flutter build web --release
      - name: Compress Web Build
        run: tar -czf kivixa-web.tar.gz -C build/web .
      - uses: actions/upload-artifact@v3
        with:
          name: web-build
          path: kivixa-web.tar.gz

  create-release:
    needs: [build-windows, build-android, build-web]
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - uses: actions/download-artifact@v3
      - uses: softprops/action-gh-release@v1
        with:
          files: |
            windows-build/kivixa-windows.zip
            android-apk/app-release.apk
            web-build/kivixa-web.tar.gz
          generate_release_notes: true
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Manual Release

1. **Create a new release** on GitHub:
   - Go to your repository
   - Click "Releases" → "Create a new release"
   - Create a tag (e.g., `v1.0.0`)

2. **Upload build artifacts**:
   - `kivixa-windows.zip` (compressed Release folder)
   - `app-release.apk` (Android APK)
   - `kivixa-web.tar.gz` (compressed web build)
   - `kivixa-x86_64.AppImage` (Linux, if built)
   - `kivixa.dmg` (macOS, if built)

3. **Write release notes**:
   ```markdown
   ## Kivixa v1.0.0
   
   ### Features
   - PDF viewing and annotation
   - Drawing tools: pen, highlighter, eraser
   - Multi-page support with autosave
   - Export annotations
   
   ### Downloads
   - **Windows**: Download `kivixa-windows.zip`, extract, and run `kivixa.exe`
   - **Android**: Download and install `app-release.apk`
   - **Web**: Visit https://yourusername.github.io/kivixa
   
   ### Changelog
   - Initial release
   ```

### Versioning Best Practices

Use [Semantic Versioning](https://semver.org/):
- **MAJOR** version (1.0.0 → 2.0.0): Breaking changes
- **MINOR** version (1.0.0 → 1.1.0): New features, backwards compatible
- **PATCH** version (1.0.0 → 1.0.1): Bug fixes, backwards compatible

Tag format: `v1.0.0`, `v1.0.1`, etc.

---

## Additional Notes

### Code Signing

For production distribution, code signing is strongly recommended:
- **Windows**: Use SignTool with a code signing certificate
- **macOS**: Required for App Store and recommended for direct distribution
- **Android**: Required for all distribution methods
- **iOS**: Required for all distribution methods

### Privacy Policy

Most app stores require a privacy policy URL. Create a simple privacy policy page explaining what data your app collects (if any).

### License

Include a `LICENSE` file in your repository. Consider:
- MIT License (permissive)
- Apache 2.0 (permissive with patent grant)
- GPL (copyleft)

### Support

Provide support channels in your README and app store listings:
- GitHub Issues
- Email
- Discord/Community forum

---

## Troubleshooting

### Common Issues

1. **Build fails on Windows**:
   - Ensure Visual Studio is installed with C++ workload
   - Run `flutter doctor -v` to check setup

2. **Android signing errors**:
   - Verify `key.properties` paths use double backslashes on Windows
   - Ensure keystore file exists and passwords are correct

3. **Web app doesn't load**:
   - Check browser console for errors
   - Ensure correct MIME types on web server
   - Try both `--web-renderer html` and `--web-renderer canvaskit`

4. **iOS build fails**:
   - Run `pod repo update` and `pod install` in `ios/` directory
   - Clean build: `flutter clean && flutter pub get`

5. **Linux missing libraries**:
   - Install all required development libraries
   - Check system GTK version compatibility

### Getting Help

- Flutter docs: https://docs.flutter.dev
- Flutter community: https://flutter.dev/community
- GitHub issues: File an issue in your repository

---

## Checklist Before Release

- [ ] Update version in `pubspec.yaml`
- [ ] Run `flutter analyze` (no issues)
- [ ] Run `flutter test` (all tests pass)
- [ ] Test on target platforms
- [ ] Update README and CHANGELOG
- [ ] Create/update privacy policy
- [ ] Prepare app store screenshots and descriptions
- [ ] Build release artifacts
- [ ] Test release builds on clean systems
- [ ] Create GitHub release with proper version tag
- [ ] Upload artifacts to release
- [ ] Submit to app stores (if applicable)
- [ ] Announce release on social media/website

---

**Happy Distributing! 🚀**
