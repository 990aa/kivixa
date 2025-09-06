# Electron App

This directory contains the Electron application setup.

## Setup

1. **Install Dependencies:**
   ```bash
   pnpm install
   ```

2. **Start the Development Server:**
   ```bash
   pnpm --filter web dev
   ```

3. **Start Electron:**
   ```bash
   pnpm --filter electron-app start
   ```

## Build

To build the application for production, run:

```bash
pnpm --filter electron-app build
```

This will create an installer in the `dist` directory.
