# Building the Kivixa Application

This document provides instructions on how to build the Kivixa application for Windows and Android.

## Using the Build Script

A Dart script is provided to automate the build process. To run the script, use the following command from the root of the project:

```bash
dart build.dart
```

The script will build the application for the following platforms:

*   Windows (Release)
*   Android (APK - Release)

## Build Output Locations

*   **Windows**: The unsigned binaries will be located in the `build\windows\runner\Release` directory.
*   **Android**: The unsigned APK will be located in the `build\app\outputs\flutter-apk` directory.

## Manual Building

You can also build the application manually using the following commands:

*   **Windows**: `flutter build windows --release`
*   **Android**: `flutter build apk --release`
