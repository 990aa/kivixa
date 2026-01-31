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
## [0.1.4] - 2026-01-11

### Changed
- Minor UI updates and improvements across Browse and Editor sections
- Enhanced settings page with improved layout

---
## [0.1.5] - 2026-01-18

### Added

- **Multi-Model Support**: Users can now download and switch between multiple AI models
  - **Phi-4 Mini** (default): General purpose, writing, math/LaTeX assistance (~2.5 GB)
  - **Qwen2.5 3B**: Writing, notes, code generation, Lua scripting (~1.9 GB)
  - **Function Gemma 270M**: Ultra-fast MCP/tool calling specialist (~180 MB)
  - **Gemma 2B**: General purpose, code generation (~1.5 GB)
  - **Gemma 7B**: Larger general purpose model (~4.7 GB)
- **Model Categories**: Models are now tagged with categories (General, Agent/MCP, Writing, Math, Code)
- **Quick Model Switcher**: Click the model chip in chat to instantly switch between downloaded models
- **Enhanced Model Selection Page**: Browse models by category, see download status, manage models
- **Model Management**: Download, load, and delete models from the Models page
- **AI Model Context Protocol (MCP)**: Full implementation of MCP for advanced AI capabilities.
  - **Multi-Model Support**: Integrated Phi-4 (Reasoning), Function Gemma (Tools), and Qwen (Code).
  - **Tool System**: Added 8 core MCP tools including File Operations (Read/Write/List), Lua Scripting (Calendar/Timer), and Markdown Export.
  - **Security Layer**: Implemented strict path sandboxing, extension allow-lists, and file size limits.
  - **User Safety**: Added confirmation dialogs for all sensitive file operations and tool executions.
  - **Documentation**: Added comprehensive guides for AI MCP usage (`docs/AI_MCP_GUIDE.md`) and testing (`docs/MCP_TESTING_GUIDE.md`).
- **MCP Chat Interface**:
  - `MCPChatController`: New controller handling tool execution, parsing, and status updates.
  - `ModelRouter`: Intelligent routing system to select the best model for specific tasks (Conversation, Tool Use, Coding).
  - **Pure Dart Implementation**: robust standalone Dart services for MCP and Model Routing with comprehensive test coverage.
- **Testing**:
  - Added 28 unit tests for Dart MCP services (`test/mcp_service_test.dart`).
  - Added 10 Rust integration tests for core native MCP logic.

### Changed
- Chat header now shows a dropdown to quickly switch between downloaded models
- Model selection page redesigned with category filters and better model cards
- Default model remains Phi-4 Mini for backward compatibility
- **Architecture**: Refactored AI services to support standalone operation without mandatory native bindings initially.

### Fixed
- **Native Library Loading**: Fixed DLL/SO loading on Windows and Linux with platform-specific path resolution
- **Build Script**: The `scripts/build_native.ps1` now correctly copies native libraries to the right output directories

---
## [0.1.6] - 2026-01-25

### Added
- **Folder Colors**: Users can now assign any custom color to folders using a full-spectrum color picker.
- **Whiteboard Orientation**: Added ability to toggle between Portrait and Landscape modes in Whiteboard settings.
- **Floating Math**: New floating tool for calculations with support for basic operations, exponents, and percentage.
- **Math Module**: Comprehensive mathematics module with Rust backend for high-performance calculations.
  - **General Tab**: Scientific calculator, expression evaluation, trigonometry, logarithms, and unit conversions
  - **Algebra Tab**: Polynomial operations, equation solving (linear, quadratic, polynomial), factorization, and simplification
  - **Calculus Tab**: 
    - Numerical derivatives (first, second, nth order)
    - Definite and indefinite integrals
    - **Partial Derivatives**: Compute partial derivatives with respect to multiple variables (∂f/∂x, ∂f/∂y, etc.)
    - **Multiple Integrals**: Double and triple integrals over rectangular regions
    - Limits with left/right-sided approach
    - Taylor series expansion
  - **Statistics Tab**: 
    - Descriptive statistics (mean, median, mode, standard deviation, variance)
    - Probability distributions (normal, exponential, binomial, Poisson)
    - Hypothesis testing:
      - One-sample and two-sample **t-tests**
      - One-sample and two-sample **z-tests** (known population standard deviation)
      - **Chi-squared test** for categorical data
      - **ANOVA** (Analysis of Variance) for comparing multiple group means
    - Confidence intervals for mean, proportion, and variance
    - Linear and polynomial regression with R², slope, intercept
  - **Discrete Tab**: Combinatorics (permutations, combinations, factorials), number theory (GCD, LCM, primality), modular arithmetic
  - **Graphing Tab**: 2D function plotting, parametric curves, polar coordinates, implicit functions
  - **Tools Tab**: Number system conversion (binary, octal, decimal, hex), constants reference, formula library
- **Native Math Library**: New `kivixa_math` Rust library with:
  - Complex number arithmetic and operations
  - Matrix operations using nalgebra (determinant, inverse, eigenvalues, LU/QR decomposition)
  - Statistical distributions via statrs (normal, exponential, binomial, poisson)
  - High-precision calculations with BigInt support
  - Parallel computation for large datasets using rayon
- **Math Build Script**: Dedicated `scripts/build_math.ps1` with flags for Release, Copy, GenerateBindings, Clean, and All operations
- **Comprehensive Tests**: 
  - 49 Rust unit tests covering all math modules
  - 27 Flutter widget tests for math UI components

### Changed
- **Update Dialog**: Removed automatic update dialog on startup. Updates can now be checked manually via "Settings > Updates".
- **Floating Hub**: Renamed "Calculator" tool to "Math".
- **Build Scripts**: Updated `build_native.ps1` and `build_math.ps1` with:
  - `-SkipClean` flag to preserve build cache
  - Profile directory support for Windows
  - Copies to `rust_builder` plugin directories for proper Flutter integration
  - Copies to all jniLibs locations for Android (arm64-v8a, armeabi-v7a)
- **Code Cleanup**: Removed unused expression evaluation helper functions (replaced by Rust backend)

### Fixed
- **Settings**: Fixed font size of settings page title for consistency.
- **Models**: Fixed issue where switching models in floating hub assistant wouldn't persist.
- **MCP**: Fixed MCP mode toggle in floating assistant window.
- **Android Build**: Fixed cross-compilation for Android targets on nightly Rust toolchain.
- **Library Loading**: Native libraries now copied to all required directories for Flutter to detect them.

---
## [0.1.7] - 2026-01-28

### Fixed
- Displaying handwritten notes in Android application
- Copy AI Engine's .so files to proper destinations

---
## [0.1.8] - 2026-01-31

### Fixed
- **Android**: Fixed loading indicator alignment in AI interface.
- **Android**: Fixed back button behavior; now supports double-tap to exit and proper navigation stack handling.
- **Android**: Fixed file browsing on Android 13+ devices using native file picker.
- **Android**: Fixed system status bar color inconsistencies.
- **Settings**: Fixed "Update available" message appearing even when the application is up to date.

---
