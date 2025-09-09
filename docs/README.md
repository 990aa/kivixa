<p align="center">
   <img src="../assets/icon.png" alt = "kivixa icon" height="100", width = "100">
</p>

# Kivixa

This repo contains the Kivixa application, with a web frontend, a mobile app, and a desktop app.

Kivixa is built with a robust and scalable data layer using Kotlin, Room, and Coroutines, focusing on high-performance data operations, efficient UI state management, and a flexible content model.

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