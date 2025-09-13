# Generating Adaptive Icons for Android

This document outlines the process for generating adaptive icons for the Android version of the Kivixa app. Adaptive icons are required for Android 8.0 (API level 26) and higher. They display a variety of shapes across different device models.

## Using Android Studio's Image Asset Studio

The easiest way to create adaptive icons is to use the **Image Asset Studio** in Android Studio.

1.  **Open the Android module in Android Studio**: Open the `android` directory of your Flutter project in Android Studio.
2.  **Open the Image Asset Studio**: In the Project window, right-click the `app` folder and select **New > Image Asset**.
3.  **Configure the icon**:
    *   **Icon Type**: Select `Launcher Icons (Adaptive and Legacy)`.
    *   **Foreground Layer**:
        *   Select the `Image` asset type.
        *   Choose the path to your icon file (e.g., `assets/icon.png`).
        *   Adjust the `Resize` slider to ensure the icon fits within the safe zone.
    *   **Background Layer**:
        *   Choose a background color or image. For a simple color background, select the `Color` asset type and choose a color.
    *   **Options**:
        *   **Generate**: Make sure `Yes` is selected.
        *   **Legacy Icon (API <= 25)**: Generate legacy icons for older Android versions.
        *   **Round Icon**: Generate a round icon.
        *   **Google Play Store Icon**: Generate a Google Play Store icon.
4.  **Click Next**: Review the icons that will be generated.
5.  **Click Finish**: Android Studio will create the icons in the appropriate `res/mipmap-*` directories.

## Further Reading

*   [Adaptive icons](https://developer.android.com/guide/practices/ui_guidelines/icon_design_adaptive)
*   [Create app icons with Image Asset Studio](https://developer.android.com/studio/write/image-asset-studio)
