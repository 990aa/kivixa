<p align="center">
   <img src="../assets/icon.png" alt = "kivixa icon" height="100", width = "100">
</p>

# Kivixa

This repo contains the Kivixa application, with a web frontend, a mobile app, and a desktop app.

## Packages

- `apps/web`: The Next.js web application.
- `apps/mobile`: The Capacitor-based mobile application.
- `apps/electron`: The Electron-based desktop application.

## Getting Started

1. **Install Dependencies:**

   ```bash
   pnpm install
   ```

2. **Development:**
   - **Web:** `pnpm --filter web dev`
   - **Mobile:** See `apps/mobile/README.md`
   - **Electron:** See `apps/electron/README.md`

## Building

- **Web:** `pnpm --filter web build`
- **Mobile:** `pnpm --filter mobile-app build`
- **Electron:** `pnpm --filter electron-app build`
