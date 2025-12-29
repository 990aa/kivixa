# Changelog

All notable changes to the Kivixa project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

--- 

## Template for Future Entries

### Added
- New features

### Changed
- Changes in existing functionality

### Deprecated
- Soon-to-be removed features

### Removed
- Removed features

### Fixed
- Bug fixes

### Security
- Security updates

---

## [0.1.0] - 2025-11-25

### Initial Release
---

## [0.1.1] - 2025-12-16

### Added
- **Native Rust Integration**: Added `kivixa_native` library for high-performance AI tasks.
- **Stylus Support**: Added support for secondary stylus button to toggle Lasso Select tool.
- **Full Screen Mode**: App now launches in full screen on desktop and immersive mode on mobile.
- **Documentation**: Added comprehensive documentation for Rust implementation and release process.

### Fixed
- **Floating Browser**: Fixed "Open in Main Browser" functionality, navigation buttons, and new tab state management.
- **Resize Cursor**: Improved resize handle sensitivity for better user experience.
- **Stylus**: Fixed eraser toggle and improved button detection during drag events.

---
## [0.1.2] - 2025-12-27

### Added
- **Markdown Video Playback**: Videos now play inline in markdown preview with full controls (play/pause, seek, fullscreen)
- **Media Dimensions**: Added width/height fields to media upload dialog for precise sizing
- **Text Alignment**: Added alignment toolbar buttons (left, center, right, justify) in markdown editor
- **Text File Media Improvements**: Full image display without cropping, actual dimensions on insert

### Fixed
- **Text File Embeds**: Fixed duplicate image creation during resize operations
- **Text File Resize**: Fixed ParentDataWidget assertion errors when resizing media
- **Image Display**: Images now show full content with proper aspect ratio (BoxFit.contain)

### Changed
- Media insert now uses HTML tags for extended features (video playback, custom dimensions)
- Improved resize handles with explicit positioning to prevent layout conflicts

---

## [0.1.3] - 2025-12-29

### Added
- **App Lifecycle Manager**: New service for managing app-wide lifecycle events
  - Idle detection with 5-minute timeout (configurable)
  - Section-based resource management (register/activate/deactivate)
  - Automatic image cache clearing on idle/background
  - `ActivityDetector` widget for tracking user interactions
  - `LifecycleAwareMixin` for easy widget integration
- **Calendar Live Updates**: Events now sync instantly across the app via `CalendarEventNotifier`
- **Browser Per-Tab History**: Each browser tab maintains its own navigation history stack

### Changed
- **Performance: SharedPreferences Caching**: Services now cache SharedPreferences instance to avoid repeated async lookups
  - `BrowserService`, `MultiTimerService`, `ChainedRoutineService`, `QuickNotesService`
- **Performance: Debounced Saves**: All save operations now debounce by 500ms to batch rapid disk writes
- **Performance: Isolate JSON Parsing**: Heavy JSON parsing offloaded to isolates via `compute()`
  - Bookmarks, history, tabs in BrowserService
  - Timer lists in MultiTimerService
  - Routine lists in ChainedRoutineService
  - Notes lists in QuickNotesService
- **UI: RepaintBoundary**: Added to `PreviewCard` to isolate repaints and reduce jank
- **Updates Dialog**: Renamed from `ReleaseNotesDialog` with added refresh button

### Fixed
- **Browser Keyboard Shortcuts**: Now reliably captured with `KeyboardListener` wrapper
- **Browser Navigation**: Back/forward buttons use per-tab history instead of WebView native navigation
- **Calendar Events**: Creating/deleting events now updates UI immediately

---
