# Kivixa Architecture Overview

This document details the backend-first architecture of Kivixa, outlining the data storage, layering, and key functional flows.

## 1. Backend-First Approach

Kivixa is built with a "backend-first" philosophy. The core logic, data persistence, and business rules are implemented and tested independently of the UI. The user interface will be built on top of this solid foundation, consuming the services and data models exposed by the backend.

## 2. Core Storage

### SQLite Database

The central source of truth is a single SQLite database file (`kivixa.db`). This approach simplifies data management, backup, and synchronization. Platform-specific drivers are used to interact with the database:
*   **Android**: `sqflite` provides the native bindings.
*   **Windows**: `sqlite3` with `sqflite_common_ffi` provides the bindings via Dart FFI.

The database schema, migrations, and data access objects (DAOs) are managed by the **Drift** framework (`lib/data/database.dart`).

### Assets Folder

Binary assets, such as imported images, PDF files, and audio recordings, are stored in the local file system in a dedicated `assets` directory next to the database. The database contains references to these files but not the files themselves.

## 3. Layering

The backend is organized into distinct layers, each with a specific responsibility:

*   **Data Layer (`lib/data`)**: The lowest level, responsible for direct database and file system interaction.
    *   `database.dart`: Defines the Drift database schema, tables, and DAOs.
    *   `repository.dart`: A generic repository interface abstracting the data source.
    *   `sqlite_repository.dart`: The concrete implementation of the repository for SQLite.
*   **Domain Layer (`lib/domain`)**: Contains the core business logic and data models of the application (e.g., `InfiniteCanvasModel`, `RenderPlanBuilder`). This layer is pure Dart and has no dependencies on Flutter or any specific data source.
*   **Services Layer (`lib/services`)**: Exposes high-level functionality and business logic to the UI. Services orchestrate calls to the data layer and other services to perform complex operations (e.g., `LibraryService`, `ExportManager`, `SettingsService`).

## 4. Key Functional Flows

*   **Export/Import/Backup**:
    *   `ExportManager`: Gathers all necessary data (from the DB) and assets (from the file system) for a given document and packages them into a single archive (e.g., `.zip`).
    *   `ImportManager`: Unpacks an archive, inserts data into the database, and places assets in the correct location.
    *   `BackupManager`: A specialized flow that periodically runs the export process for all user data to create safe recovery points.
*   **AI Provider Adapters**:
    *   The `AIActionsService` uses a set of adapters to communicate with different AI backends (OpenAI, Ollama, etc.). This keeps the core logic separate from the specifics of any single AI provider's API.
*   **Rendering Plan Builders**:
    *   Services like `RenderPlanBuilder` and `MinimapPlanBuilder` do not perform rendering themselves. Instead, they query the database and prepare an efficient, ordered list of drawing commands and assets. The UI layer later consumes this plan and executes the actual rendering, ensuring that business logic remains separate from the presentation.
