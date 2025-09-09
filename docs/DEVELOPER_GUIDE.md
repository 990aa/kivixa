# Kivixa: Developer Guide

Welcome to the developer guide for Kivixa. This document provides a technical overview of the project's modern architecture and a guide for setting up your development environment and contributing to the codebase.

## 1. Philosophy

Kivixa is built with a strong emphasis on performance, scalability, and maintainability. Our core principles include:

*   **Kotlin-first:** Leveraging Kotlin's modern features, conciseness, and safety.
*   **Structured Concurrency:** Utilizing Kotlin Coroutines for asynchronous operations, ensuring responsiveness and efficient resource management.
*   **Robust Data Layer:** Employing Room Persistence Library for SQLite database management, providing an abstraction layer over raw SQL and ensuring data integrity.
*   **Clear Separation of Concerns:** A well-defined layered architecture separates UI logic from business logic and data persistence.
*   **Testability:** Designing components to be easily testable, promoting a stable and reliable codebase.

## 2. Getting Started: Development Environment

### Prerequisites

*   [Java Development Kit (JDK) 11 or higher](https://www.oracle.com/java/technologies/javase-jdk11-downloads.html)
*   [Android Studio](https://developer.android.com/studio) or [IntelliJ IDEA](https://www.jetbrains.com/idea/)
*   Git

### Setup

1.  **Clone the repository:**
    ```bash
    git clone <repository_url>
    cd kivixa
    ```

2.  **Open in IDE:** Open the `kivixa` project in Android Studio or IntelliJ IDEA.

3.  **Sync Gradle:** Allow Gradle to sync and download all necessary dependencies.

4.  **Run Tests:** To verify your setup, run the existing unit and integration tests.
    ```bash
    # Depending on your build system, e.g., Gradle command
    ./gradlew test
    ```

## 3. Project Architecture

Kivixa follows a layered architecture, primarily implemented in Kotlin, to ensure modularity, testability, and scalability.

### Core Layers

*   **Domain Layer (`domain/`):**
    *   Contains pure Kotlin data classes representing the core business entities (e.g., `Document`, `Page`, `StrokeChunk`).
    *   UI-agnostic and framework-independent.
    *   Includes sealed `Result` types for consistent error handling across the application.

*   **Data Layer (`database/`, `filestore/`):**
    *   **Room Database:** Manages the application's SQLite database (`KivixaDatabase`). Defines entities (`@Entity`) and Data Access Objects (`@Dao`).
    *   **DAOs (`database/dao/`):** Interfaces or abstract classes that provide methods for interacting with the database. They include:
        *   Standard CRUD operations.
        *   Batched operations for high-throughput writes (e.g., `StrokeChunkDao`, `MinimapTileDao`).
        *   Full-Text Search (FTS5) capabilities for `TextBlock` and `Comment` content.
    *   **FileStore (`filestore/`):** Handles persistence of large binary assets (e.g., page thumbnails) to the device's file system, including hashing and de-duplication.

*   **Repository Layer (`repository/`):**
    *   Acts as a single source of truth for data, abstracting the underlying data sources (Room, FileStore).
    *   Orchestrates operations from multiple DAOs and the `FileStore` to fulfill complex use cases (e.g., Document CRUD, Page Flow management, Template operations).
    *   Returns domain models, ensuring the UI interacts with a clean, consistent data representation.
    *   All expensive operations run on `Dispatchers.IO` using Kotlin Coroutines.

*   **Manager/Service Classes (`settings/`, `strokes/`, `pageflow/`, `templates/`):**
    *   These are specialized classes that encapsulate specific business logic or manage particular aspects of the application's state or behavior.
    *   Examples include `SettingsManager` (debounced persistence of UI state), `StrokeAppendManager` (batched stroke writes), `ReplayEngine` (efficient stroke rendering), `PageFlowManager` (page creation logic), and `TemplatesService` (template management with caching).

### Concurrency and Data Flow

*   **Kotlin Coroutines:** Used extensively for asynchronous programming. Operations that involve I/O (database, file system) are executed on `Dispatchers.IO` to prevent blocking the main thread.
*   **Kotlin Flow:** Used for reactive data streams, allowing UI components to observe changes in the database or other data sources and react efficiently.

## 4. Database Schema

The application's database schema is defined by the Room `@Entity` classes in `database/model/`. Key entities include:

*   `Document`: Represents a user document, including its `pageFlowMode`.
*   `Page`: Individual pages within a document.
*   `Layer`: Layers within a page, containing content.
*   `StrokeChunk`: Binary blobs of vector stroke data, now including `tileX` and `tileY` for infinite canvas support.
*   `TextBlock`: Text content, also with `tileX` and `tileY`.
*   `Template`: Defines page styles, backgrounds, grids, and template types.
*   `UserSetting`: Stores user preferences and application settings, including editor UI state and edge offsets.
*   `SplitLayoutState`: Persists the state of split-screen layouts.
*   `PageThumbnail`: Stores metadata for cached page thumbnails.
*   `Comment`, `Outline`, `Link`, `Favorite`, `JobQueue`, `MinimapTile`, etc.

### Full-Text Search (FTS5)

FTS5 virtual tables are used for efficient full-text search on `TextBlock` content (`text_blocks_fts`) and `Comment` content (`comments_fts`). Triggers ensure these FTS tables are kept in sync with their respective content tables.

### Database Migrations

Schema evolution is handled via Room's `Migration` classes within `KivixaDatabase.kt`. Each migration ensures safe and consistent updates to the database schema as new features are introduced.

## 5. How to Contribute

When contributing, please consider the layered architecture:

*   **New Data Entity/Table:** Define a new `@Entity` in `database/model/`, create a corresponding `@Dao` in `database/dao/`, and add it to `KivixaDatabase.kt` (including a `Migration` if necessary).
*   **New Domain Model:** Create a data class in `domain/`.
*   **New Use Case:** Implement the logic in the `Repository` layer, orchestrating calls to DAOs and `FileStore`.
*   **Specialized Logic/State Management:** Create a new Manager/Service class (e.g., in `settings/`, `strokes/`) if the logic is complex or manages its own state.
*   **UI Changes:** Interact with the `Repository` or Manager/Service classes to fetch and update data.

Always ensure your changes are covered by tests and adhere to the existing coding patterns and conventions.

## 6. Code Style and Conventions

*   Follow standard Kotlin coding conventions.
*   Prioritize immutability for data classes.
*   Use `val` over `var` where possible.
*   Ensure proper use of coroutine scopes and dispatchers.
*   Write clear, concise, and self-documenting code.

## 7. Building the Application

Refer to the `README.md` for general build instructions. For platform-specific build details, consult the `apps/<platform>/README.md` files.