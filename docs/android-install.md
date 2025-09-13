# Installing the Unsigned Android APK

This guide explains how to install an unsigned Kivixa APK on an Android device for testing purposes.

## 1. Enable "Install from Unknown Apps"

Android blocks the installation of apps from outside the Google Play Store by default for security. You must grant permission to the app you'll use to install the APK (e.g., your file manager or browser).

1.  **Open Settings**: Go to your device's **Settings** app.
2.  **Navigate to Apps**: Tap on **Apps** or **Apps & notifications**.
3.  **Find Your Installer App**: Go to **Special app access** > **Install unknown apps**. (This path may vary slightly depending on your Android version and manufacturer).
4.  **Grant Permission**: Find the app you will use to open the `.apk` file (e.g., "Files by Google", "Chrome", or "My Files") and toggle the switch to **Allow** installation from this source.

## 2. How to Install the APK

You can install the app either by transferring the file to your device or by using the Android Debug Bridge (`adb`).

### Method A: Device File Transfer

1.  **Transfer APK**: Copy the `kivixa.apk` file from your computer to your Android device's storage (e.g., into the `Downloads` folder).
2.  **Open File Manager**: Use a file manager app on your device to navigate to where you saved the APK.
3.  **Tap to Install**: Tap on the `kivixa.apk` file.
4.  **Confirm Installation**: A prompt will appear. Tap **Install**.

### Method B: Using ADB (For Developers)

1.  **Enable USB Debugging**: On your device, go to **Settings > About phone** and tap **Build number** seven times to enable Developer options. Then, go to **Settings > System > Developer options** and enable **USB debugging**.
2.  **Connect to PC**: Connect your device to your computer via USB.
3.  **Run ADB Command**: Open a terminal or command prompt on your computer and run the following command, replacing the path with the actual location of your APK file:
    ```sh
    adb install path/to/kivixa.apk
    ```

## 3. Runtime Permissions

Kivixa will request the following permissions at runtime as they are needed:

*   **Storage (Files and media)**:
    *   **Why it's needed**: To create and access the `kivixa.db` database, save exported documents (like PDFs and images), and import files from your device's storage.
*   **Microphone**:
    *   **Why it's needed**: For the "Ink Audio Sync" feature, which allows you to record audio clips that are synchronized with your handwriting. This permission is only requested when you explicitly try to start a recording.

The app is designed to be privacy-focused, and these permissions are only used for their stated core functionality.
