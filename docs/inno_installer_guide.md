# Kivixa Installer Guide

The installer script is located at `windows/installer/kivixa-installer.iss`. It uses Inno Setup (ISCC) to compile a setup executable.

### Key Features
*   **Automatic Versioning:** Reads the `VERSION` file (repo root) to set the installer version.
*   **Modern Styling:** Uses a gradient background and custom wizard styling.
*   **Uninstall Logic:** Prompts users to optionally delete their local data (`Documents\Kivixa`) during uninstall.
*   **Icon:** Uses the native Windows `.ico` resource from `windows\runner\resources\app_icon.ico`.

## Prerequisites
1.  **Flutter Environment:** Able to run `flutter build windows --release`.
2.  **Inno Setup:** Installed on your machine (ensure `iscc` is in your PATH).

## Build Instructions
 
 1.  **Build the Application:**
     Generate the release executable for Windows.
      flutter build windows --release

     This will create the necessary files in `build\windows\runner\Release\`.
 
 2.  **Compile the Installer using Inno Setup IDE:**
     *   Open the **Inno Setup Compiler** application. If you don't have it 
     installed, download it from [jrsoftware.org/isinfo.php](
     https://jrsoftware.org/isinfo.php).
     *   In the Inno Setup IDE, go to **File -> Open**.
     *   Navigate to your project directory and open the installer script: 
     `windows/installer/kivixa-installer.iss`.
     *   Go to **Project -> Compile**.
     *   The compiler will process the script and generate the setup executable (
     `.exe`) in the output directory specified within the script (
     `build_windows_installer/`). The output file will be named similar to `Kivixa-Setu
     0.1.0.exe`.
     
## Configuration

### Versioning
The installer version is derived dynamically from the `VERSION` file in the repository root.
To update the version:
1.  Run `dart run scripts/bump_version.dart`.
2.  Recompile the installer.

### Customization

*   **Colors/Gradient:** Modify the `InitializeWizard` procedure in the `[Code]` section of the `.iss` file. Adjust the `DrawGradient` calls with different hex colors (format: `$00BBGGRR`).
*   **Icons:** The installer uses `windows\runner\resources\app_icon.ico`. Ensure this file exists and is a valid Windows Icon file.
*   **Data Paths:** The uninstall logic specifically targets `{userdocs}\Kivixa`. If the app changes its data storage location, update the `CleanupUserData` function in the `.iss` file.

## Troubleshooting
*   **Missing Files:** Ensure you have run `flutter build windows --release` *before* compiling the installer. The script looks for files in `..\..\build\windows\runner\Release\*`.
*   **Icon Errors:** If the icon is missing, the compiler will fail. Verify the path `windows\runner\resources\app_icon.ico`.
