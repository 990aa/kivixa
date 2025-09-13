# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2025-09-13

### Added

-   **Complete Backend Foundation**: This version represents a complete, backend-first implementation of the application's core logic, ready for future UI development.
-   **Normalized SQLite Schema**: Implemented a robust and scalable database schema using the Drift framework, with clear data separation and migrations.
-   **Core Services Layer**:
    -   `LibraryService`: Manages document creation, deletion, and organization.
    -   `SettingsService`: Handles user preferences and application settings.
    -   `SplitLayoutService` & `SplitScreenPersistence`: Manages and saves split-screen view states.
    -   `OutlineCommentsService` & `ScannedPagesOutlineService`: Logic for generating outlines from PDFs and scanned images, and for managing comments.
    -   `TiledThumbnailsService`: Efficiently generates and caches page thumbnails.
    -   `StrokeStore` & `ReplayEngine`: Manages stroke data for the infinite canvas and provides playback capabilities.
    -   `TemplatesService`: Manages page backgrounds and templates.
    -   `ExportManager`, `ImportManager`, `BackupManager`: Handles exporting documents to various formats, importing data, and creating user backups.
    -   `AIActionsService`: A provider-agnostic layer for integrating with AI models (local and remote).
    -   `SanitizedLogsService` & `LocalFeatureFlags`: Provides debugging tools and safe rollout capabilities.
-   **Security**: Secure storage for API keys using platform-native credential managers.
-   **Unsigned Builds**: Added build configurations for creating unsigned APK, AppBundle, and Windows executables for testing and distribution.

## [1.0.2] - 2025-08-24

### Changed

-   Toolbar buttons now highlight when selected.
-   The "insert page" buttons have been merged into a single button that inserts a page after the current page.

## [1.0.0] - 2025-08-23

### Added

-   **Initial Release of Kivixa**
-   Core canvas engine with infinite vertical scrolling.
-   Page management system (add, insert, tear, customize size, color, and type).
-   Advanced drawing tools: Pen (multiple styles, pressure sensitivity), Eraser, Laser Pointer.
-   Interactive geometry guides: Ruler, Set Square, and Compass with edge-snapping.
-   Shape drawing tools: Rectangle, Circle, and Parallelogram with resize/rotate handles.
-   Image import via drag-and-drop and file selection, with full manipulation.
-   Ability to draw and write directly on top of placed images.
-   SQLite database integration for robust, automatic saving of all content.
-   PDF export for entire notebooks or individual pages.
-   `electron-builder` configuration for creating a standalone Windows installer.
-   Comprehensive user and developer documentation.
