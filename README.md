# kivixa

This repository contains the following structure:

- **apps/web**: Next.js + React + TypeScript web application. Independent `package.json`.
- **apps/electron**: Electron app (main/preload). Independent `package.json`.
- **apps/mobile**: Capacitor Android shell. Independent `package.json`.
- **core/**: Shared code (libraries, utilities, etc.).
- **data/**: SQLite schema and migrations.
- **python_services/**: Optional local Python utilities.
- **assets/**: Project assets (e.g., `icon.png`, `icon.ico`).
- **docs/**: Documentation and guides.

Each app folder manages its own dependencies and build scripts. No workspace managers or symlinks are used. Node.js 20+ and TypeScript strict mode are recommended for all Node-based apps.
