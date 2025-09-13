# Sync Provider Integration

This directory contains the integration points for cloud sync providers like Google Drive and OneDrive.

## For Contributors

The sync adapters (`GoogleDriveSyncAdapter`, `OneDriveSyncAdapter`, etc.) are disabled by default because they require API keys to function. To enable them for local development, you will need to:

1.  **Obtain API Keys**: Follow the developer documentation for the respective cloud provider to create a project and get API credentials (e.g., client ID, client secret).

2.  **Local Configuration**: Store these keys in a local configuration file that is **not** checked into version control (e.g., using a `.env` file and `flutter_dotenv`).

3.  **Enable the Adapter**: In the `sync_adapter.dart` file, modify the `isEnabled` getter for the desired adapter to return `true` when the necessary keys are present in your local configuration.

This approach ensures that the app remains fully functional for all users out-of-the-box (offline-first) and that no secret keys are committed to the repository, while still allowing developers to test and contribute to sync functionality.