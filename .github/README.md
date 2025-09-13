<p align="center">
   <img src="../assets/icon.png" alt = "kivixa icon" height="100", width = "100">
</p>

# Kivixa Project

## Project Goals

Kivixa is a digital notebook application with a focus on an infinite canvas, powerful import/export features, and a flexible, backend-first architecture. The primary goal is to create a robust and performant cross-platform application for Windows and Android. This initial development phase is focused exclusively on implementing the backend services and data persistence layers. The UI will be built in a later phase.

## Folder Layout

The project is organized with a clear separation of concerns:

- `lib/`: Contains all the core Dart code.
  - `data/`: Handles SQLite database interaction (Drift framework).
  - `domain/`: Core business logic and data models.
  - `services/`: High-level services that orchestrate backend tasks.
  - `features/`: Will contain UI-related code (widgets, blocs/providers) in the future.
  - `platform/`: Platform-specific implementations (e.g., storage paths).
- `assets/`: Contains application icons and other static assets.
  - `icon.png`: The primary application icon (used for Android, etc.).
  - `icon.ico`: The application icon for Windows.
- `docs/`: Project documentation, including architecture, setup guides, and parity checklists.
- `android/`: Android-specific project files.
- `windows/`: Windows-specific project files.
- `test/`: Unit and integration tests.

## How to Run Basic Builds

These instructions are for creating unsigned, debuggable builds of the application.

### Build for Android

1.  **Connect an Android Device**: Ensure you have an Android device connected with USB debugging enabled, or an emulator running.
2.  **Run the Build Command**: Open a terminal in the project root and run:
    ```sh
    flutter build apk --debug
    ```
3.  **Find the APK**: The output APK will be located at `build/app/outputs/flutter-apk/app-debug.apk`. You can install this on your device using `adb install`.

### Build for Windows

1.  **Enable Developer Mode**: Make sure you have enabled "Developer Mode" in your Windows settings.
2.  **Run the Build Command**: Open a terminal in the project root and run:
    ```sh
    flutter build windows --debug
    ```
3.  **Find the Executable**: The output executable will be located at `build/windows/x64/runner/Debug/kivixa.exe`. You can run this file directly.