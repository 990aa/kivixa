# Installing the Unsigned Windows Build

This guide explains how to run the unsigned Windows build for Kivixa, manage its data, and verify its integrity.

## 1. How to Run the Application

The Flutter build process compiles the Windows application into an `.exe` file and its required dependencies.

1.  **Locate the Build Folder**: Navigate to the project's root directory and find the `build` folder. The executable is located at:
    ```
    build\windows\x64\runner\Release\
    ```
2.  **Run the Executable**: Double-click on `kivixa.exe` to run it.
3.  **Windows SmartScreen**: Because the application is unsigned, Windows Defender SmartScreen will likely block it.
    *   Click on "**More info**".
    *   Click on the "**Run anyway**" button that appears.

## 2. Verifying Checksums (If Provided)

If a checksum file (e.g., `sha256sum.txt`) is provided with the build, you can verify the integrity of the executable.

1.  **Open PowerShell**: Open a PowerShell window in the `Release` directory (you can Shift + Right-click in the folder and select "Open PowerShell window here").
2.  **Run Checksum Command**: Execute the following command, replacing `kivixa.exe` with the actual filename if it differs.
    ```powershell
    Get-FileHash .\kivixa.exe -Algorithm SHA256 | Format-List
    ```
3.  **Compare Hashes**: Compare the `Hash` value produced by the command with the one provided in the checksum file. They should match exactly.

## 3. Application Data Location

Kivixa stores its local database and other assets in the user's Documents folder to ensure data is easily accessible and backed up.

*   **Database File**: `C:\Users\<YourUsername>\Documents\Kivixa\kivixa.db`
*   **Assets & Logs**: `C:\Users\<YourUsername>\Documents\Kivixa\assets\`

*(Note: The exact path may vary based on your Windows configuration.)*

## 4. How to Delete Local Data

If you need to reset the application to its initial state or clear all your data, you can delete the application's data folder.

1.  **Close the Application**: Ensure Kivixa is not running.
2.  **Navigate to Documents**: Open File Explorer and go to your Documents folder.
3.  **Delete the Folder**: Find and delete the entire `Kivixa` directory.

**Warning**: This action is irreversible and will delete all your notes, settings, and other data.
