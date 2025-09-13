# Kivixa Sync Adapters

This directory contains the interfaces and stubs for cloud sync providers.

## Contributor's Note

Sync functionality is disabled by default to ensure the app is fully functional offline without requiring API keys.

To enable sync with a provider for local development:

1.  **Obtain API Keys**: Follow the developer documentation for the desired cloud service (e.g., Google Drive, OneDrive) to get your own API keys for a test application.
2.  **Configure Locally**: Create a `sync_config.dart` file in this directory (which is git-ignored) and add your keys:

    ```dart
    const Map<String, String> googleDriveKeys = {
      'apiKey': 'YOUR_API_KEY',
      'apiSecret': 'YOUR_API_SECRET',
    };

    const Map<String, String> oneDriveKeys = {
      'apiKey': 'YOUR_API_KEY',
      'apiSecret': 'YOUR_API_SECRET',
    };
    ```

3.  **Enable in Code**: In the main application setup, you can then conditionally enable a sync provider with these keys.

**Important**: Do not commit your API keys or the `sync_config.dart` file to the repository.
