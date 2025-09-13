# Performance Engineering Guide

This document outlines the key performance strategies and optimizations implemented in Kivixa's backend to ensure a smooth and responsive user experience, especially on low-end devices.

## 1. Database Optimizations (SQLite PRAGMAs)

The database is configured with several PRAGMA statements to maximize performance for our specific write-heavy workload.

*   **`PRAGMA journal_mode=WAL`**: Write-Ahead Logging is enabled to allow for high concurrency, meaning the UI can read from the database while a background service is writing to it without causing locks.
*   **`PRAGMA synchronous=NORMAL`**: In WAL mode, this setting ensures a good balance between safety and speed. It's durable but avoids extra syncs on every single write, batching them instead.
*   **`PRAGMA foreign_keys=ON`**: Enforces data integrity at the database level, which is crucial for preventing corrupted data.
*   **`PRAGMA cache_size=-20000`**: Sets the page cache to 20MB, providing a generous in-memory cache for frequently accessed data, which significantly reduces disk I/O.

## 2. Stroke & Content Caching

*   **Stroke Chunking**: To handle infinitely large canvases, strokes are not stored in a single massive blob. Instead, they are chunked and indexed spatially in the `StrokeStore`. When the user pans or zooms, only the chunks visible in the current viewport are loaded into memory, keeping the memory footprint low.
*   **Thumbnail Caching**: Page and layer thumbnails are generated once and cached aggressively by the `TiledThumbnailsService`. Thumbnails are only regenerated if the underlying content has changed, preventing costly re-rendering during normal navigation.

## 3. Asynchronous Processing

Heavy, CPU-bound tasks are offloaded from the main UI thread to background isolates to prevent UI jank (stuttering).

*   **Isolate Usage**:
    *   **Waveform Generation**: When an audio clip is recorded, the waveform visualization is generated in a separate isolate.
    *   **PDF Rasterization**: The `PdfRasterService` renders PDF pages into images in the background, so the UI remains responsive while importing large documents.
    *   **OCR & Search Indexing**: Text recognition and search index updates are performed in isolates to avoid blocking user interaction.

*   **Replay Engine Streaming**: The `ReplayEngine` does not load an entire drawing into memory to play it back. Instead, it streams the stroke data from the database and sends it to the renderer incrementally, allowing for smooth playback of even very large and complex drawings.

## 4. Guidance for Low-End Devices

The application is designed to be mindful of resource constraints.
*   **Feature Flags**: Experimental or resource-intensive features (like the `experimentalInfiniteCanvasCache`) are controlled by `LocalFeatureFlags`. These can be disabled by default to ensure a reliable baseline experience.
*   **Graceful Degradation**: If a device is low on memory, services will reduce cache sizes and perform more frequent garbage collection. Non-critical background tasks are deferred until the device is idle.
