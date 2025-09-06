# Mobile App

This directory contains the mobile application setup using Capacitor.

## Setup

1. **Install Dependencies:**
   ```bash
   pnpm install
   ```

2. **Build the Web App:**
   ```bash
   pnpm run build:web
   ```

3. **Sync Assets:**
   ```bash
   pnpm run sync
   ```

4. **Open in Android Studio:**
   ```bash
   pnpm run open
   ```

## Scripts

- `init`: Initializes Capacitor.
- `android`: Adds the Android platform.
- `sync`: Syncs the web app build with the native project.
- `copy`: Copies the web assets to the native project.
- `open`: Opens the native project in its IDE (Android Studio).
- `build`: Builds the web app and syncs the assets.
- `build:web`: Builds the Next.js web application.
