# Kivixa: Developer Guide

Welcome to the developer guide for Kivixa. This document provides a technical overview of the project's architecture and a guide for setting up your development environment and contributing to the codebase.

## 1. Philosophy

Kivixa is built on the principle of a clean separation between the application's backend logic (window management, database operations) and its frontend rendering and user interaction. It uses a state-driven, multi-layered canvas system for a responsive and extensible user experience.

## 2. Getting Started: Development Environment

### Prerequisites

*   [Node.js](https://nodejs.org/) (LTS version recommended)
*   A text editor (e.g., VS Code)

### Setup

1.  **Clone the repository:**
    ```bash
    git clone <repository_url>
    cd kivixa
    ```

2.  **Install dependencies:** This will install Electron, electron-builder, and all other necessary packages.
    ```bash
    npm install
    ```

3.  **Run the application in development mode:** This will launch the app with developer tools enabled.
    ```bash
    npm start
    ```

## 3. Project Architecture

Kivixa follows the standard Electron architecture with a Main process and a Renderer process.

### Core Concepts

*   **Main Process:** A single Node.js environment responsible for creating and managing application windows, handling native OS interactions, and performing all backend operations like database access. It is the entry point of the application (`main.js`).
*   **Renderer Process:** A sandboxed Chromium browser environment responsible for rendering the user interface (HTML/CSS) and handling all user interaction on the canvas (`renderer/`). It cannot directly access Node.js modules or the file system.

### Main Process (`main.js`)

*   **Responsibilities:**
    *   Creates the `BrowserWindow`.
    *   Initializes the SQLite database connection.
    *   Listens for and responds to IPC (Inter-Process Communication) messages from the renderer.
    *   Handles all `CRUD` operations for the database.

### Renderer Process (`renderer/`)

*   **`index.html`:** The main HTML file for the user interface.
*   **`style.css`:** Styles for the UI.
*   **`renderer.js`:** The core of the application's interactivity. Its responsibilities include:
    *   **State Management:** A central `state` object tracks the current tool, active objects, canvas properties, etc.
    *   **Multi-Layer Canvas:** Uses four stacked canvases for high performance:
        1.  `pages-canvas`: Renders the static page backgrounds (color, lines, grid).
        2.  `drawing-canvas`: Renders all committed, permanent content (strokes, shapes, images).
        3.  `live-canvas`: A temporary layer for rendering in-progress freehand strokes.
        4.  `tool-overlay-canvas`: A temporary layer for rendering interactive guides (ruler, compass) and shape manipulation handles.
    *   **Tool Handlers (State Pattern):** A `toolHandlers` object manages the application's current mode (e.g., drawing with a pen, defining a shape, manipulating an object). This keeps the event-handling logic clean and modular.

### Inter-Process Communication (IPC)

*   **`preload.js`:** This script acts as a secure bridge between the Main and Renderer processes.
*   It uses Electron's `contextBridge` to expose specific main process functionalities (e.g., `window.electron.getNote()`) to the renderer.
*   This prevents the renderer from having full access to the `ipcRenderer` object, which is a security best practice.

## 4. Database Schema

The application uses a SQLite database (`notebook.db`) managed by the `main.js` process. The key table is `notes`.

*   **`notes` table:**
    *   `id`: The primary key for the note.
    *   `title`: The title of the note.
    *   `content`: A `TEXT` column that stores the **entire state of the canvas notebook as a JSON string**. This includes all pages, objects, strokes, images, and their properties.
    *   `folder_id`, `created_at`, `updated_at`: For organization and metadata.

## 5. How to Contribute

### Modifying an Existing Feature

1.  Identify which process is responsible for the feature (Main for data, Renderer for UI/interaction).
2.  Locate the relevant code (`main.js` for IPC, `renderer.js` for canvas logic).
3.  For UI changes, look for the relevant `ToolHandler` in `renderer.js`.
4.  Make your changes, following the existing coding patterns.

### Adding a New Feature (e.g., a New Tool)

Here is the standard workflow for adding a new interactive tool:

1.  **Create a Class (if needed):** In `renderer.js`, create a new class for your tool (e.g., `class MyNewTool extends BaseTool`). Implement its `draw()` method.
2.  **Add UI:** Add a button for your new tool to `renderer/index.html`.
3.  **Create a Tool Handler:** In `renderer.js`, add a new entry to the `toolHandlers` object. Implement its `onActivate`, `onPointerDown`, `onPointerMove`, and `onPointerUp` methods.
4.  **Wire it Up:** In `setupEventListeners()`, add a click listener to your new button that calls `switchTool(toolHandlers.myNewTool)`.

### Code Style and Conventions

*   Please follow the existing code style (indentation, naming conventions).
*   Use the state-driven `toolHandlers` pattern for any new interactive modes.
*   Keep direct DOM manipulation to a minimum. Let the `render()` loop handle drawing based on the current state.

## 6. Building the Application

This project uses `electron-builder` to create distributable installers.

1.  **Add an Icon:** Before building, you must create an application icon at `build/icon.ico`.
2.  **Run the build script:** The following command will package the application and create a Windows installer in the `/dist` directory.
    ```bash
    npm run dist
    ```
